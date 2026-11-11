import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_details_changes.dart';
import 'package:hamrash_admin/api/models/students/student_filter.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/api/models/students/student_registration.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_photo_field.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/photo_draft.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/views/students/student_detail/student_detail_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';

import 'student_detail_fakes.dart';

Future<(StudentDetailViewModel, FakeStudents)> _loaded(
  StudentProfile student, {
  OrganizationMemberRole role = OrganizationMemberRole.principal,
}) async {
  final service = FakeStudents(student);
  final model = StudentDetailViewModel(
    school: schoolFor(role),
    studentId: student.id,
    students: service,
    now: () => DateTime(2026, 11, 11),
  );
  await model.load();
  return (model, service);
}

void main() {
  group('the page reads like the design', () {
    test('hero, class card and subjects', () async {
      final (model, _) = await _loaded(abdullahi());

      expect(model.identityMeta, 'JSS 1B · KCL/2026/0021');
      expect(model.statusLabel, 'Active');
      expect(model.classValue, 'JSS 1B · Ibrahim Bello');
      expect(model.classCaption, '2026/27');
      expect(model.subjectsCaption, 'Subjects · 2 core, 2 optional');
      expect(model.subjectsValue, 'Agricultural Science, French');
    });

    test('details and personal rows', () async {
      final (model, _) = await _loaded(abdullahi());

      expect(model.admittedLabel, '8 Sep 2026');
      expect(model.dateOfBirthLabel, '2 Mar 2014');
      expect(model.stateOfOriginLabel, 'Kano · Nassarawa');
      expect(model.bloodGroup, 'O+');
      expect(model.medicalNotes, startsWith('Asthma'));
    });

    test('a student with no class or no optional subjects', () async {
      final (none, _) = await _loaded(abdullahi(placed: false));
      expect(none.identityMeta, 'KCL/2026/0021');
      expect(none.classValue, 'Not in a class this session');
      expect(none.classCaption, isNull);

      final bare = abdullahi().copyWith(
        placement: const StudentPlacement(
          sessionId: 's',
          sessionName: '2026/27',
          armId: 'a',
          armName: 'A',
          classId: 'c',
          className: 'JSS 1',
        ),
      );
      final (model, _) = await _loaded(bare);
      expect(model.subjectsValue, 'No optional subjects');
      expect(model.classValue, 'JSS 1A');
    });

    test('a student who has left gets the banner words', () async {
      final (model, _) = await _loaded(
        abdullahi(status: StudentStatusFilter.withdrawn),
      );

      expect(model.leftOnLabel, 'Withdrawn on 10 Nov 2026');
      expect(
        model.leftExplanation,
        "They're off the JSS 1B list. Their results and parents stay on record.",
      );
      expect(model.classCaption, 'Last placed 2026/27');
      expect(model.showPersonal, isFalse);
      expect(model.showAccess, isFalse);
      expect(model.canChangeClass, isFalse);
    });

    test('the Access card words follow the login', () async {
      final states = {
        null: (AccessState.notOnApp, null),
        loginWith(OrganizationMemberStatus.invited, code: 'R4TB8KXW'): (
          AccessState.codeReady,
          'Invited 8 Nov',
        ),
        loginWith(OrganizationMemberStatus.active): (
          AccessState.onApp,
          'Joined 3 Sep 2026',
        ),
        loginWith(OrganizationMemberStatus.suspended): (
          AccessState.suspended,
          'Joined 3 Sep 2026',
        ),
      };
      for (final entry in states.entries) {
        final (model, _) = await _loaded(abdullahi(login: entry.key));
        final apps = model.accessApps();
        expect(apps.single.appName, 'Hamrash Student');
        expect(apps.single.roles, isEmpty);
        expect(apps.single.state, entry.value.$1);
        expect(model.accessCaption, entry.value.$2);
      }
    });

    test('only someone not on the app can be invited by tapping', () async {
      final (fresh, _) = await _loaded(abdullahi());
      expect(fresh.canInvite, isTrue);
      expect(fresh.accessApps(onInvite: () {}).single.onTap, isNotNull);

      final (onApp, _) = await _loaded(
        abdullahi(login: loginWith(OrganizationMemberStatus.active)),
      );
      expect(onApp.canInvite, isFalse);
      expect(onApp.accessApps(onInvite: () {}).single.onTap, isNull);
    });
  });

  group('who sees and does what', () {
    test('a bursar only reads', () async {
      final (model, _) = await _loaded(
        abdullahi(),
        role: OrganizationMemberRole.bursar,
      );

      expect(model.canEdit, isFalse);
      expect(model.canChangeClass, isFalse);
      expect(model.showPersonal, isFalse);
      expect(model.showAccess, isFalse);
      expect(model.canInvite, isFalse);
    });

    test('a principal edits but cannot manage logins or remove', () async {
      final (model, _) = await _loaded(abdullahi());

      expect(model.canEdit, isTrue);
      expect(model.showAccess, isTrue);
      expect(model.canManageAccess, isFalse);
    });

    test('an admin manages logins and removes', () async {
      final (model, _) = await _loaded(
        abdullahi(),
        role: OrganizationMemberRole.admin,
      );
      expect(model.canManageAccess, isTrue);
    });
  });

  group('changes', () {
    test('saving details sends them and marks the page changed', () async {
      final (model, service) = await _loaded(abdullahi());

      final error = await model.saveDetails(
        StudentDetailsChanges.of(model.student),
      );

      expect(error, isNull);
      expect(service.savedChanges?.firstName, 'Abdullahi');
      expect(model.changed, isTrue);
      expect(service.calls.where((c) => c == 'getStudent'), hasLength(2));
    });

    test('a refused save returns the database reason', () async {
      final (model, service) = await _loaded(abdullahi());
      service.failWith = const SupabaseRefusal(
        'Check the details and try again.',
      );

      final error = await model.saveDetails(
        StudentDetailsChanges.of(model.student),
      );

      expect(error, 'Check the details and try again.');
      expect(model.changed, isFalse);
    });

    test('an unexpected failure gets the fallback', () async {
      final (model, service) = await _loaded(abdullahi());
      service.failWith = Exception('offline');

      expect(
        await model.setStatus(StudentStatusFilter.withdrawn),
        "Couldn't change the status. Try again.",
      );
    });

    test('status: the same one asks nothing', () async {
      final (model, service) = await _loaded(abdullahi());

      await model.setStatus(StudentStatusFilter.active);
      expect(service.savedStatus, isNull);

      expect(await model.setStatus(StudentStatusFilter.graduated), isNull);
      expect(service.savedStatus, StudentStatusFilter.graduated);
    });

    test('moving reports the subjects dropped', () async {
      final (model, service) = await _loaded(abdullahi());
      service.droppedOnMove = 2;

      final result = await model.moveToArm('arm-1a');

      expect(service.movedTo, 'arm-1a');
      expect(result.dropped, 2);
      expect(result.error, isNull);
    });

    test('the move sheet offers the arms of their class', () async {
      final (model, _) = await _loaded(abdullahi());

      final arms = await model.loadArmChoices();

      expect(arms?.map((a) => a.label), ['JSS 1A', 'JSS 1B', 'JSS 1C']);
      expect(arms?.last.caption, '29 students · No lead yet');
      final (none, _) = await _loaded(abdullahi(placed: false));
      expect(await none.loadArmChoices(), isNull);
    });

    test('optional subjects are saved against what they had', () async {
      final (model, service) = await _loaded(abdullahi());

      await model.saveOptionalSubjects({'french', 'music'});

      expect(service.optionalWas, {'agric', 'french'});
      expect(service.savedOptional, {'french', 'music'});
    });
  });

  group('login and removal', () {
    test('the invite returns the code and the message to send', () async {
      final (model, _) = await _loaded(abdullahi());

      final result = await model.invite();

      expect(result.error, isNull);
      expect(result.code, 'R4TB8KXW');
      expect(
        model.shareMessage('R4TB8KXW'),
        'Hi Abdullahi, Kings College has added you on Hamrash. Open the '
        'Hamrash student app, sign in with Apple or Google, and enter '
        'R4TB-8KXW.',
      );
    });

    test('a refused invite says why', () async {
      final (model, service) = await _loaded(abdullahi());
      service.failWith = const SupabaseRefusal(
        'Only active students can be given a login',
      );

      final result = await model.invite();

      expect(result.code, isNull);
      expect(result.error, 'Only active students can be given a login');
    });

    test(
      'suspending, restoring and cancelling keep the sheet open on refusal',
      () async {
        final (model, service) = await _loaded(
          abdullahi(login: loginWith(OrganizationMemberStatus.active)),
          role: OrganizationMemberRole.admin,
        );

        await model.setSuspended(true);
        expect(service.suspended, isTrue);

        service.failWith = const SupabaseRefusal(
          'Only the owner and admins can do this.',
        );
        await expectLater(
          model.setSuspended(false),
          throwsA(isA<AppAlertError>()),
        );
        await expectLater(model.cancelInvite(), throwsA(isA<AppAlertError>()));
      },
    );

    test('removing says what goes and closes the page', () async {
      final (model, service) = await _loaded(
        abdullahi(login: loginWith(OrganizationMemberStatus.active)),
        role: OrganizationMemberRole.admin,
      );

      expect(model.removeTitle, 'Remove Abdullahi Yusuf?');
      expect(model.removeBullets, [
        'Their class place and subjects for 2026/27 go',
        'Their student app login stops working',
        'Their parents stay, with any other children',
      ]);

      await model.remove();

      expect(service.removedId, 'st1');
      expect(model.removed, isTrue);
    });

    test('without a login the bullets leave the login line out', () async {
      final (model, _) = await _loaded(abdullahi());
      expect(model.removeBullets, hasLength(2));
    });

    test('a refused removal throws for the confirm sheet', () async {
      final (model, service) = await _loaded(
        abdullahi(),
        role: OrganizationMemberRole.admin,
      );
      service.failWith = const SupabaseRefusal(
        'Only the owner and admins can do this.',
      );

      await expectLater(model.remove(), throwsA(isA<AppAlertError>()));
      expect(model.removed, isFalse);
    });
  });

  group('parents', () {
    test('the first parent a student gets is the primary contact', () async {
      final (empty, service) = await _loaded(abdullahi(parents: const []));
      expect(empty.nextParentIsPrimary, isTrue);
      await empty.linkParent('p9', ParentRelationship.father);
      expect(service.linked?.primary, isTrue);

      final (model, other) = await _loaded(abdullahi());
      expect(model.nextParentIsPrimary, isFalse);
      await model.linkParent('p9', ParentRelationship.guardian);
      expect(other.linked?.primary, isFalse);
    });

    test('the Add a parent sheet is the Add student one, seeded', () async {
      final (model, _) = await _loaded(abdullahi());

      final sheet = model.parentSheetModel();

      expect(sheet.studentFirstName, 'Abdullahi');
      // The parents they already have are "already added".
      expect(sheet.parents.map((p) => p.match?.id), ['p1', 'p2']);
      expect(sheet.parents.first.relationship, ParentRelationship.mother);
      sheet.dispose();
    });

    test('a parent the sheet found is linked, not created', () async {
      final (model, service) = await _loaded(abdullahi());

      final error = await model.addParentFrom(
        AddedParent.existing(
          const ParentMatch(
            id: 'p7',
            title: 'Mr',
            firstName: 'Sani',
            lastName: 'Danladi',
            phone: '+2348052209134',
          ),
          ParentRelationship.father,
        ),
      );

      expect(error, isNull);
      expect(service.linked?.parentId, 'p7');
      expect(service.linked?.relationship, ParentRelationship.father);
      expect(service.linked?.primary, isFalse);
      expect(service.newParent, isNull);
    });

    test('a new parent is created with their photo and linked', () async {
      final (model, service) = await _loaded(abdullahi(parents: const []));
      final photo = PhotoDraft(MediaKind.parentPhoto)
        ..status = AppPhotoStatus.added
        ..uploaded = const RegistrationPhoto(id: 'img1', url: 'https://x/img1');

      final error = await model.addParentFrom(
        AddedParent.created(
          title: 'Mr',
          firstName: 'Sani',
          lastName: 'Danladi',
          phone: '+2348052209134',
          relationship: ParentRelationship.father,
          photo: photo,
          email: 'sani@example.com',
          occupation: 'Engineer',
          address: '1 Road',
        ),
      );

      expect(error, isNull);
      expect(service.newParent?.photoId, 'img1');
      expect(service.newParent?.primary, isTrue);
      expect(service.newParent?.phone, '+2348052209134');
      expect(service.newParent?.email, 'sani@example.com');
    });

    test('a refused link says why', () async {
      final (model, service) = await _loaded(abdullahi());
      service.failWith = const SupabaseRefusal(
        'They are already linked to this student.',
      );

      expect(
        await model.addParentFrom(
          AddedParent.existing(
            const ParentMatch(
              id: 'p7',
              firstName: 'Sani',
              lastName: 'Danladi',
              phone: '+2348052209134',
            ),
            ParentRelationship.father,
          ),
        ),
        'They are already linked to this student.',
      );
    });

    test('unlinking the primary hands it to the next parent', () async {
      final (model, service) = await _loaded(abdullahi());

      expect(
        model.unlinkMessage(mother),
        "They stop being Abdullahi's parent here and won't see their "
        'results. Mr Musa Yusuf becomes the primary contact.',
      );
      expect(
        model.unlinkMessage(father),
        "They stop being Abdullahi's parent here and won't see their "
        'results.',
      );

      await model.unlink(mother);
      expect(service.unlinked?.parentId, 'p1');
      expect(service.unlinked?.newPrimary, 'p2');
      await model.unlink(father);
      expect(service.unlinked?.newPrimary, isNull);
    });

    test('changing the relationship', () async {
      final (model, service) = await _loaded(abdullahi());

      expect(
        await model.changeRelationship(father, ParentRelationship.guardian),
        isNull,
      );
      expect(service.changedTo, ParentRelationship.guardian);
    });

    test('parent captions read as the design has them', () {
      expect(mother.caption, 'Mother · Primary contact');
      expect(father.caption, 'Father · 0803 112 4455');
      expect(mother.displayName, 'Mrs Halima Yusuf');
      expect(mother.initials, 'HY');
    });
  });
}
