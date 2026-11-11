import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/student_registration.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/parent_profile.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_details_changes.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A new parent's phone already belongs to a parent in the school. The
/// database refuses rather than merging; the app should reuse that parent.
class ParentAlreadyInSchool extends SupabaseRefusal {
  const ParentAlreadyInSchool(super.message);
}

/// Students and their parents. Registering goes through one RPC
/// (`register_student`, migration 31) so a student is saved completely or
/// not at all.
///
/// Refusals come back as [SupabaseRefusal] with a readable message.
class StudentService {
  StudentService(this._supabase);

  final SupabaseClient _supabase;

  static const leadersOnly = "Only the school's leaders can register students.";

  /// How many students one page of the list holds.
  static const pageSize = 30;

  /// One page of the school's students (`list_students`): search, class,
  /// arm, subject and status run on the server, in class order, with the
  /// filtered total and each arm's count. For a subject filter every row
  /// carries that subject and the teacher assigned to it in the student's
  /// arm. Pass [cursor] from the previous page, and start again with null
  /// when [filter] changes. The session is the school's current one.
  Future<StudentPage> listStudentsPage({
    required String organizationId,
    StudentFilter filter = StudentFilter.initial,
    int limit = pageSize,
    String? cursor,
  }) => runRefusable(
    'listStudentsPage',
    () async {
      try {
        final result = await _supabase.rpc(
          'list_students',
          params: {
            'p_organization_id': organizationId,
            'p_search': filter.trimmedSearch.isEmpty
                ? null
                : filter.trimmedSearch,
            'p_class_id': filter.schoolClass?.id,
            'p_arm_id': filter.arm?.id,
            'p_subject_id': filter.subject?.id,
            'p_statuses': filter.statuses.isEmpty
                ? null
                : [for (final status in filter.statuses) status.value],
            'p_sort': filter.sort.value,
            'p_limit': limit,
            'p_cursor': cursor,
          },
        );
        return StudentPage.fromJson(Map<String, dynamic>.from(result as Map));
      } on PostgrestException catch (error) {
        // Bad arguments and stale cursors are refused with 22023 and a
        // message written for people.
        if (error.code == '22023') throw SupabaseRefusal(error.message);
        rethrow;
      }
    },
    log: (page) => {
      'organization_id': organizationId,
      'count': page.rows.length,
      'total': page.total,
      'has_more': page.nextCursor != null,
    },
    forbidden: "You don't have access to the students.",
  );

  /// The most rows one phone search reads before they are compared by
  /// digits here.
  static const _searchLimit = 20;

  /// Parents in the school whose phone is [phone], however it was saved
  /// (0803…, 803…, +234 803…). One request: the parent row with the first
  /// names of their children embedded.
  ///
  /// The filter keeps rows whose phone has the same digits in the same
  /// order (anything may sit between them, such as spaces or a +234), then
  /// the digits are compared exactly here. Returns an empty list for a
  /// number that isn't 10 digits after +234.
  Future<List<ParentMatch>> findParentsByPhone({
    required String organizationId,
    required String phone,
  }) => runRefusable(
    'findParentsByPhone',
    () async {
      final digits = PhoneFormat.digitsAfterPrefix(phone);
      if (digits.length != 10) return const <ParentMatch>[];
      final rows = await _supabase
          .from('parents')
          .select(ParentMatch.columns)
          .eq('organization_id', organizationId)
          .ilike('phone', '%${digits.split('').join('%')}')
          .limit(_searchLimit);
      return [
        for (final row in rows)
          if (ParentMatch.fromJson(row) case final match
              when match.phoneDigits == digits)
            match,
      ];
    },
    log: (matches) => {
      'organization_id': organizationId,
      'count': matches.length,
    },
    forbidden: leadersOnly,
  );

  /// Registers a student with their parents, placement and optional
  /// subjects in one transaction. Every refusal migration 31 raises is
  /// returned with its own message; a new parent whose phone is taken comes
  /// back as [ParentAlreadyInSchool].
  Future<RegisteredStudent> registerStudent(StudentRegistration registration) =>
      runRefusable(
        'registerStudent',
        () async {
          try {
            final result = await _supabase.rpc(
              'register_student',
              params: registration.toParams(),
            );
            return RegisteredStudent.fromJson(result as Map<String, dynamic>);
          } on PostgrestException catch (error) {
            final refusal = refusalFor(error);
            if (refusal != null) throw refusal;
            rethrow;
          }
        },
        log: (student) => {
          'student_id': student.id,
          'parents': student.parentIds.length,
          'subjects': student.subjectIds.length,
        },
        forbidden: leadersOnly,
      );

  /// The readable refusal for one of `register_student`'s own errors, or
  /// null for anything else (a dropped connection, a missing function).
  static SupabaseRefusal? refusalFor(PostgrestException error) {
    final message = error.message.trim();
    if (message.isEmpty) return null;
    return switch (error.code) {
      '23505' when message.contains('already a parent') =>
        ParentAlreadyInSchool(message),
      '42501' => const SupabaseRefusal(leadersOnly),
      '22023' ||
      'P0001' ||
      'P0002' ||
      '23505' ||
      '23514' => SupabaseRefusal(message),
      _ => null,
    };
  }

  // ───────────────────────── one student ─────────────────────────

  static const _leadersOnly =
      'Only the owner, admins, the principal and vice principals can change '
      'students.';
  static const _ownersOnly = 'Only the owner and admins can do this.';

  /// One student for their page: the record with its login and private
  /// details, their parents, and where they sit in the current session (arm,
  /// lead teacher, the subjects the arm offers and the optional ones they
  /// take). A few small reads, the independent ones at once. A student with no
  /// class this session has no placement.
  Future<StudentProfile> getStudent({
    required String organizationId,
    required String studentId,
  }) => runRefusable(
    'getStudent',
    () async {
      final results = await Future.wait<Object?>([
        _supabase
            .from('students')
            .select(StudentProfile.columns)
            .eq('organization_id', organizationId)
            .eq('id', studentId)
            .single(),
        _supabase
            .from('student_parents')
            .select(StudentParent.columns)
            .eq('organization_id', organizationId)
            .eq('student_id', studentId),
        _supabase
            .from('academic_sessions')
            .select('id,name')
            .eq('organization_id', organizationId)
            .eq('is_current', true)
            .maybeSingle(),
      ]);
      final row = Map<String, dynamic>.from(results[0] as Map);
      final parents = [
        for (final link in results[1] as List)
          StudentParent.fromJson(Map<String, dynamic>.from(link as Map)),
      ]..sort(_primaryFirst);
      final session = results[2] as Map?;
      final placement = session == null
          ? null
          : await _readPlacement(
              organizationId: organizationId,
              studentId: studentId,
              sessionId: session['id'] as String,
              sessionName: session['name'] as String,
            );
      return StudentProfile.fromJson(
        row,
        placement: placement,
        parents: parents,
      );
    },
    log: (student) => {'id': student.id, 'parents': student.parents.length},
    forbidden: "You don't have access to this student.",
  );

  static int _primaryFirst(StudentParent a, StudentParent b) {
    if (a.isPrimaryContact != b.isPrimaryContact) {
      return a.isPrimaryContact ? -1 : 1;
    }
    return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
  }

  Future<StudentPlacement?> _readPlacement({
    required String organizationId,
    required String studentId,
    required String sessionId,
    required String sessionName,
  }) async {
    final row = await _supabase
        .from('student_placements')
        .select(
          'arm_id,class_arms!student_placements_arm_fkey(id,name,class_id,'
          'classes!class_arms_class_fkey(id,name))',
        )
        .eq('organization_id', organizationId)
        .eq('student_id', studentId)
        .eq('session_id', sessionId)
        .maybeSingle();
    if (row == null) return null;
    final arm = Map<String, dynamic>.from(row['class_arms'] as Map);
    final schoolClass = Map<String, dynamic>.from(arm['classes'] as Map);
    final armId = row['arm_id'] as String;

    final results = await Future.wait<List<Map<String, dynamic>>>([
      _supabase
          .from('arm_subjects')
          .select(
            'subject_id,is_compulsory,'
            'subjects!arm_subjects_subject_fkey(name,code,sort_order)',
          )
          .eq('organization_id', organizationId)
          .eq('arm_id', armId),
      _supabase
          .from('student_subjects')
          .select('subject_id')
          .eq('organization_id', organizationId)
          .eq('student_id', studentId)
          .eq('session_id', sessionId),
      _supabase
          .from('class_teachers')
          .select('is_lead,staff!class_teachers_staff_fkey(first_name,last_name)')
          .eq('organization_id', organizationId)
          .eq('arm_id', armId)
          .eq('session_id', sessionId),
    ]);

    final offers = [
      for (final offer in results[0])
        (
          sort: ((offer['subjects'] as Map)['sort_order'] as num).toInt(),
          value: StudentSubjectOffer(
            subjectId: offer['subject_id'] as String,
            name: (offer['subjects'] as Map)['name'] as String,
            code: (offer['subjects'] as Map)['code'] as String?,
            isCompulsory: offer['is_compulsory'] as bool,
          ),
        ),
    ]..sort(
        (a, b) => a.sort != b.sort
            ? a.sort.compareTo(b.sort)
            : a.value.name.compareTo(b.value.name),
      );

    final teachers = [...results[2]]
      ..sort((a, b) => (b['is_lead'] == true ? 1 : 0) - (a['is_lead'] == true ? 1 : 0));
    final lead = teachers.isEmpty ? null : teachers.first['staff'] as Map?;

    return StudentPlacement(
      sessionId: sessionId,
      sessionName: sessionName,
      armId: armId,
      armName: arm['name'] as String,
      classId: schoolClass['id'] as String,
      className: schoolClass['name'] as String,
      leadTeacher: lead == null
          ? null
          : '${lead['first_name']} ${lead['last_name']}'.trim(),
      offers: [for (final offer in offers) offer.value],
      chosenOptionalIds: {
        for (final row in results[1]) row['subject_id'] as String,
      },
    );
  }

  /// The arms of [classId] with this session's headcount and lead teacher,
  /// for the Move to another arm sheet. Switched-off arms come back too (the
  /// sheet greys them).
  Future<List<ArmChoice>> listArmChoices({
    required String organizationId,
    required String classId,
    required String className,
    required String sessionId,
  }) => runRefusable(
    'listArmChoices',
    () async {
      final rows = await _supabase
          .from('class_arms')
          .select(
            'id,name,is_active,student_placements(count),'
            'class_teachers(is_lead,staff!class_teachers_staff_fkey(first_name,last_name))',
          )
          .eq('organization_id', organizationId)
          .eq('class_id', classId)
          .eq('student_placements.session_id', sessionId)
          .eq('class_teachers.session_id', sessionId);
      final arms = [
        for (final row in rows)
          () {
            final placements = row['student_placements'] as List;
            final teachers = [...(row['class_teachers'] as List)]
              ..sort(
                (a, b) =>
                    ((b as Map)['is_lead'] == true ? 1 : 0) -
                    ((a as Map)['is_lead'] == true ? 1 : 0),
              );
            final lead = teachers.isEmpty
                ? null
                : (teachers.first as Map)['staff'] as Map?;
            return ArmChoice(
              armId: row['id'] as String,
              name: row['name'] as String,
              className: className,
              students: placements.isEmpty
                  ? 0
                  : ((placements.first as Map)['count'] as num).toInt(),
              isActive: row['is_active'] as bool,
              leadTeacher: lead == null
                  ? null
                  : '${lead['first_name']} ${lead['last_name']}'.trim(),
            );
          }(),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return arms;
    },
    log: (arms) => {'class_id': classId, 'count': arms.length},
    forbidden: "You don't have access to this class.",
  );

  /// Saves the student's own details through `update_student`, sending every
  /// other field back unchanged (it takes the whole record).
  Future<void> updateStudentDetails({
    required StudentProfile student,
    required StudentDetailsChanges changes,
  }) => runRefusable(
    'updateStudentDetails',
    () => _updateStudent(
      student,
      status: student.status,
      changes: changes,
    ),
    log: (_) => {'id': student.id},
    forbidden: _leadersOnly,
    invalid: 'Check the details and try again.',
  );

  /// Changes the student's status (active, graduated, transferred or
  /// withdrawn) and sends every other field back unchanged.
  Future<void> setStudentStatus({
    required StudentProfile student,
    required StudentStatusFilter status,
  }) => runRefusable(
    'setStudentStatus',
    () => _updateStudent(
      student,
      status: status,
      changes: StudentDetailsChanges.of(student),
    ),
    log: (_) => {'id': student.id, 'status': status.value},
    forbidden: _leadersOnly,
  );

  Future<void> _updateStudent(
    StudentProfile student, {
    required StudentStatusFilter status,
    required StudentDetailsChanges changes,
  }) async {
    await _supabase.rpc(
      'update_student',
      params: {
        'p_student_id': student.id,
        'p_first_name': changes.firstName,
        'p_last_name': changes.lastName,
        'p_middle_name': changes.middleName,
        'p_admission_number': student.admissionNumber,
        'p_gender': changes.gender?.value,
        'p_admission_date': _dateOnly(changes.admissionDate),
        'p_photo_id': student.photoId,
        'p_photo_url': student.photoUrl,
        'p_status': status.value,
        'p_date_of_birth': _dateOnly(changes.dateOfBirth),
        'p_address': changes.address,
        'p_state_of_origin': changes.stateOfOrigin,
        'p_lga': changes.lga,
        'p_blood_group': changes.bloodGroup,
        'p_genotype': changes.genotype,
        'p_medical_notes': changes.medicalNotes,
      },
    );
  }

  /// `update_student` takes dates as `yyyy-MM-dd`.
  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Moves the student to [armId] for the current session
  /// (`move_student_to_arm`) and drops the optional subjects that arm
  /// doesn't offer. Returns how many choices were dropped.
  Future<int> moveToArm({
    required String studentId,
    required String armId,
  }) => runRefusable(
    'moveToArm',
    () async =>
        (await _supabase.rpc(
              'move_student_to_arm',
              params: {'p_student_id': studentId, 'p_arm_id': armId},
            ))
            as int,
    log: (dropped) => {'student_id': studentId, 'dropped': dropped},
    forbidden: _leadersOnly,
  );

  /// Sets the optional subjects the student takes this session to exactly
  /// [subjectIds]: adds the new ones first, then takes off the rest. The
  /// database refuses a subject the arm doesn't offer as optional.
  Future<void> setOptionalSubjects({
    required String organizationId,
    required String studentId,
    required String sessionId,
    required Set<String> current,
    required Set<String> subjectIds,
  }) => runRefusable(
    'setOptionalSubjects',
    () async {
      final add = subjectIds.difference(current);
      final remove = current.difference(subjectIds);
      if (add.isNotEmpty) {
        await _supabase.from('student_subjects').insert([
          for (final id in add)
            {
              'organization_id': organizationId,
              'student_id': studentId,
              'session_id': sessionId,
              'subject_id': id,
            },
        ]);
      }
      if (remove.isNotEmpty) {
        final removed = await _supabase
            .from('student_subjects')
            .delete()
            .eq('student_id', studentId)
            .eq('session_id', sessionId)
            .inFilter('subject_id', remove.toList())
            .select('subject_id');
        refuseIfNothingChanged(removed, _leadersOnly);
      }
    },
    log: (_) => {'student_id': studentId, 'count': subjectIds.length},
    forbidden: _leadersOnly,
  );

  /// Creates (or reissues) the student's invite and returns the raw
  /// 8-character code (`invite_student`).
  Future<String> inviteStudent(String studentId) => runRefusable(
    'inviteStudent',
    () async =>
        await _supabase.rpc(
              'invite_student',
              params: {'p_student_id': studentId},
            )
            as String,
    log: (_) => {'student_id': studentId},
    forbidden: "You can't issue a login for this student.",
  );

  /// Cancels an unclaimed invite by deleting the membership; the student's
  /// `member_id` goes back to null.
  Future<void> cancelInvite(String memberId) => runRefusable(
    'cancelStudentInvite',
    () async {
      final removed = await _supabase
          .from('organization_members')
          .delete()
          .eq('id', memberId)
          .select('id');
      refuseIfNothingChanged(removed, _ownersOnly);
    },
    log: (_) => {'member_id': memberId},
    forbidden: _ownersOnly,
  );

  /// Suspends the student's login or restores it.
  Future<void> setSuspended({
    required String memberId,
    required bool suspended,
  }) => runRefusable(
    'setStudentSuspended',
    () async {
      final changed = await _supabase
          .from('organization_members')
          .update({
            'status': suspended
                ? OrganizationMemberStatus.suspended.value
                : OrganizationMemberStatus.active.value,
          })
          .eq('id', memberId)
          .select('id');
      refuseIfNothingChanged(changed, _ownersOnly);
    },
    log: (_) => {'member_id': memberId, 'suspended': suspended},
    forbidden: _ownersOnly,
  );

  /// Removes the student and their records. Migration 28's trigger takes
  /// their login with them.
  Future<void> removeStudent(String studentId) => runRefusable(
    'removeStudent',
    () async {
      final removed = await _supabase
          .from('students')
          .delete()
          .eq('id', studentId)
          .select('id');
      refuseIfNothingChanged(removed, _ownersOnly);
    },
    log: (_) => {'id': studentId},
    forbidden: _ownersOnly,
    inUse: "This student has records that can't be removed. Change their "
        'status instead.',
  );

  // ───────────────────────── parents ─────────────────────────

  /// Links an existing parent to the student. The first parent a student has
  /// is their primary contact.
  Future<void> linkParent({
    required String organizationId,
    required String studentId,
    required String parentId,
    required ParentRelationship relationship,
    required bool primary,
  }) => runRefusable(
    'linkParent',
    () async {
      await _supabase.from('student_parents').insert({
        'organization_id': organizationId,
        'student_id': studentId,
        'parent_id': parentId,
        'relationship': relationship.value,
        'is_primary_contact': primary,
      });
    },
    log: (_) => {'student_id': studentId, 'parent_id': parentId},
    forbidden: _leadersOnly,
    duplicate: 'They are already linked to this student.',
  );

  /// Adds a parent who isn't in the school yet and links them to the
  /// student. Returns the new parent's id.
  Future<String> createAndLinkParent({
    required String organizationId,
    required String studentId,
    required String? title,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String occupation,
    required String address,
    required ParentRelationship relationship,
    required bool primary,
    String? photoId,
    String? photoUrl,
  }) => runRefusable(
    'createAndLinkParent',
    () async {
      final parent = await _supabase.rpc(
        'create_parent',
        params: {
          'p_organization_id': organizationId,
          'p_first_name': firstName,
          'p_last_name': lastName,
          'p_phone': phone,
          'p_title': title,
          'p_email': email,
          'p_occupation': occupation,
          'p_address': address,
          'p_photo_id': photoId,
          'p_photo_url': photoUrl,
        },
      );
      final parentId = (parent as Map)['id'] as String;
      await _supabase.from('student_parents').insert({
        'organization_id': organizationId,
        'student_id': studentId,
        'parent_id': parentId,
        'relationship': relationship.value,
        'is_primary_contact': primary,
      });
      return parentId;
    },
    log: (parentId) => {'student_id': studentId, 'parent_id': parentId},
    forbidden: _leadersOnly,
    duplicate: 'A parent with this phone number is already at the school.',
  );

  /// Changes how [parentId] is related to the student.
  Future<void> setParentRelationship({
    required String studentId,
    required String parentId,
    required ParentRelationship relationship,
  }) => runRefusable(
    'setParentRelationship',
    () async {
      final changed = await _supabase
          .from('student_parents')
          .update({'relationship': relationship.value})
          .eq('student_id', studentId)
          .eq('parent_id', parentId)
          .select('parent_id');
      refuseIfNothingChanged(changed, _leadersOnly);
    },
    log: (_) => {'student_id': studentId, 'parent_id': parentId},
    forbidden: _leadersOnly,
  );

  /// Unlinks [parentId] from the student. The parent stays at the school with
  /// any other children. If they were the primary contact, [newPrimaryId]
  /// (when given) takes over.
  Future<void> unlinkParent({
    required String studentId,
    required String parentId,
    String? newPrimaryId,
  }) => runRefusable(
    'unlinkParent',
    () async {
      final removed = await _supabase
          .from('student_parents')
          .delete()
          .eq('student_id', studentId)
          .eq('parent_id', parentId)
          .select('parent_id');
      refuseIfNothingChanged(removed, _leadersOnly);
      if (newPrimaryId != null) {
        await _supabase
            .from('student_parents')
            .update({'is_primary_contact': true})
            .eq('student_id', studentId)
            .eq('parent_id', newPrimaryId);
      }
    },
    log: (_) => {'student_id': studentId, 'parent_id': parentId},
    forbidden: _leadersOnly,
  );

  // ───────────────────────── one parent ─────────────────────────

  /// One parent for their page: the record with its login and private
  /// details, and their children with the arm each sits in this session.
  Future<ParentProfile> getParent({
    required String organizationId,
    required String parentId,
  }) => runRefusable(
    'getParent',
    () async {
      final results = await Future.wait<Object?>([
        _supabase
            .from('parents')
            .select(ParentProfile.columns)
            .eq('organization_id', organizationId)
            .eq('id', parentId)
            .single(),
        _supabase
            .from('student_parents')
            .select(ParentChild.columns)
            .eq('organization_id', organizationId)
            .eq('parent_id', parentId),
        _supabase
            .from('academic_sessions')
            .select('id')
            .eq('organization_id', organizationId)
            .eq('is_current', true)
            .maybeSingle(),
      ]);
      final sessionId = (results[2] as Map?)?['id'] as String?;
      final children = [
        for (final link in results[1] as List)
          ParentChild.fromJson(
            Map<String, dynamic>.from(link as Map),
            sessionId: sessionId,
          ),
      ]..sort(
          (a, b) => a.isPrimaryContact != b.isPrimaryContact
              ? (a.isPrimaryContact ? -1 : 1)
              : a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      return ParentProfile.fromJson(
        Map<String, dynamic>.from(results[0] as Map),
        children: children,
      );
    },
    log: (parent) => {'id': parent.id, 'children': parent.children.length},
    forbidden: "You don't have access to this parent.",
  );

  /// Saves the parent's details through `update_parent`, sending every
  /// other field back unchanged.
  Future<void> updateParentDetails({
    required ParentProfile parent,
    required ParentDetailsChanges changes,
  }) => runRefusable(
    'updateParentDetails',
    () async {
      await _supabase.rpc(
        'update_parent',
        params: {
          'p_parent_id': parent.id,
          'p_first_name': changes.firstName,
          'p_last_name': changes.lastName,
          'p_phone': changes.phone,
          'p_title': changes.title,
          'p_gender': null,
          'p_alt_phone': parent.altPhone,
          'p_photo_id': parent.photoId,
          'p_photo_url': parent.photoUrl,
          'p_is_active': parent.isActive,
          'p_email': changes.email,
          'p_occupation': changes.occupation,
          'p_address': changes.address,
        },
      );
    },
    log: (_) => {'id': parent.id},
    forbidden: _leadersOnly,
    duplicate: 'A parent with this phone number is already at the school.',
  );

  /// Creates (or reissues) the parent's invite and returns the raw code
  /// (`invite_parent`).
  Future<String> inviteParent(String parentId) => runRefusable(
    'inviteParent',
    () async =>
        await _supabase.rpc('invite_parent', params: {'p_parent_id': parentId})
            as String,
    log: (_) => {'parent_id': parentId},
    forbidden: "You can't issue a login for this parent.",
  );

  /// Removes the parent record, its links to their children and its login.
  Future<void> removeParent(String parentId) => runRefusable(
    'removeParent',
    () async {
      final removed = await _supabase
          .from('parents')
          .delete()
          .eq('id', parentId)
          .select('id');
      refuseIfNothingChanged(removed, _ownersOnly);
    },
    log: (_) => {'id': parentId},
    forbidden: _ownersOnly,
  );
}
