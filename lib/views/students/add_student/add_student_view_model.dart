import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/cloudflare_models/cloudflare_errors.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/students/parent_match.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_registration.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/app_logger.dart';
import 'package:hamrash_admin/core/bottomSheets/app_photo_options_sheet.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/utils/validation_util.dart';
import 'package:hamrash_admin/core/widgets/app_photo_field.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/photo_draft.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_catalog.dart';
import 'package:image_picker/image_picker.dart';

/// The wizard's steps, in order. Subjects is skipped when the chosen arm
/// offers no optional subjects.
enum AddStudentStep {
  student('Student'),
  personal('Personal details'),
  parents('Parents'),
  placement('Class'),
  subjects('Subjects'),
  review('Review');

  const AddStudentStep(this.label);

  /// The eyebrow's name: "STEP 1 OF 6 · STUDENT".
  final String label;
}

/// What the Add a parent sheet is showing.
enum ParentSheetMode { search, found, newParent }

/// One parent on the Parents step: an existing parent found by phone, or a
/// new one that registering creates.
class AddedParent {
  AddedParent.existing(ParentMatch this.match, this.relationship)
    : title = match.title,
      firstName = match.firstName,
      lastName = match.lastName,
      phone = match.phone,
      photo = null,
      email = null,
      occupation = null,
      address = null;

  AddedParent.created({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.relationship,
    required PhotoDraft this.photo,
    required String this.email,
    required String this.occupation,
    required String this.address,
    this.title,
  }) : match = null;

  /// Set for an existing parent.
  final ParentMatch? match;
  final String? title;
  final String firstName;
  final String lastName;

  /// As saved (existing) or as it will be stored (new, `+234…`).
  final String phone;
  final ParentRelationship relationship;

  /// A new parent's optional photo.
  final PhotoDraft? photo;

  /// A new parent's private details, trimmed; null for an existing parent.
  final String? email;
  final String? occupation;
  final String? address;

  bool get isExisting => match != null;

  /// "Mrs Ngozi Okafor".
  String get displayName =>
      [?title, '$firstName $lastName'.trim()].join(' ').trim();

  /// "Ngozi Okafor", for initials.
  String get fullName => '$firstName $lastName'.trim();

  String get phoneDigits => PhoneFormat.digitsAfterPrefix(phone);

  /// "Mother · 0803 555 0142".
  String get caption =>
      '${relationship.label} · ${PhoneFormat.nationalDisplay(phone)}';

  RegistrationParent toRegistration({required bool isPrimary}) =>
      switch (match) {
        final ParentMatch match => ExistingRegistrationParent(
          parentId: match.id,
          relationship: relationship,
          isPrimaryContact: isPrimary,
        ),
        null => NewRegistrationParent(
          title: title,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          photo: photo?.ready,
          email: email ?? '',
          occupation: occupation ?? '',
          address: address ?? '',
          relationship: relationship,
          isPrimaryContact: isPrimary,
        ),
      };
}

/// 9.5–9.11 · Add a student: who they are, their optional personal
/// details, their parents, their class and arm, their optional subjects,
/// then a review. Nothing is saved until
/// Register, which sends everything to `register_student` in one call.
///
/// Reads, each done once:
///  * the parent search reads the school's parents by phone ([findParent]);
///  * the Class step reads the current session and the classes and arms
///    through a [TeachingCatalog];
///  * choosing an arm reads what it offers ([SubjectService.listArmOfferings]);
///    the same read gives the optional subjects and the compulsory count.
class AddStudentViewModel extends BaseViewModel {
  AddStudentViewModel({
    required this.school,
    StudentService? students,
    SubjectService? subjects,
    ClassStructureService? structure,
    ImageService? images,
    ImagePicker? picker,
    TeachingCatalog? catalog,
    DateTime? today,
  }) : _students = students ?? locator<StudentService>(),
       _subjects = subjects ?? locator<SubjectService>(),
       _imagesOverride = images,
       _picker = picker ?? ImagePicker(),
       catalog =
           catalog ??
           TeachingCatalog(organizationId: school.id, structure: structure),
       _today = today ?? DateTime.now() {
    admissionDate = DateTime(_today.year, _today.month, _today.day);
  }

  final MemberSchool school;
  final StudentService _students;
  final SubjectService _subjects;
  final ImageService? _imagesOverride;
  final ImagePicker _picker;
  final DateTime _today;

  /// The current session and the classes and arms, read once.
  final TeachingCatalog catalog;

  ImageService get _images => _imagesOverride ?? locator<ImageService>();

  // ── Navigation ──────────────────────────────────────────────────────────

  AddStudentStep _step = AddStudentStep.student;
  bool _returnToReview = false;

  AddStudentStep get step => _step;

  /// The steps this student goes through. Subjects drops out once the arm is
  /// known to offer no optional subjects.
  List<AddStudentStep> get steps => [
    for (final each in AddStudentStep.values)
      if (each != AddStudentStep.subjects || !skipsSubjects) each,
  ];

  bool get skipsSubjects =>
      arm != null && offeringsReady && optionalSubjects.isEmpty;

  /// Zero-based position of [step] among [steps].
  int get stepIndex => steps.indexOf(_step).clamp(0, steps.length - 1);
  int get stepCount => steps.length;

  /// "Step 3 of 6 · Parents" for the step on screen.
  String get eyebrow => stepEyebrow(_step);

  /// The eyebrow of [each] page. Pages stay built while hidden, so each one
  /// asks for its own.
  String stepEyebrow(AddStudentStep each) {
    final list = steps;
    final index = list.indexOf(each);
    final number = index < 0 ? list.length : index + 1;
    return 'Step $number of ${list.length} · ${each.label}';
  }

  bool canContinueFrom(AddStudentStep step) => switch (step) {
    AddStudentStep.student => studentValid,
    AddStudentStep.personal => personalValid,
    AddStudentStep.parents => parents.isNotEmpty,
    AddStudentStep.placement => placementValid,
    AddStudentStep.subjects => true,
    AddStudentStep.review => canRegister,
  };

  bool get canContinue => canContinueFrom(_step);

  /// Moves to the next step when this one is valid. After an Edit from the
  /// review, goes straight back to the review (via Subjects when the new arm
  /// has some to pick).
  void next() {
    if (!canContinue || _step == AddStudentStep.review) return;
    final AddStudentStep target;
    if (_returnToReview) {
      target =
          _step == AddStudentStep.placement &&
              !skipsSubjects &&
              optionalSubjects.isNotEmpty
          ? AddStudentStep.subjects
          : AddStudentStep.review;
    } else {
      final list = steps;
      target = list[list.indexOf(_step) + 1];
    }
    _go(target);
  }

  /// The previous step, or false on the first one (the screen then asks
  /// before closing).
  bool back() {
    final list = steps;
    final index = list.indexOf(_step);
    if (index <= 0) return false;
    _returnToReview = false;
    _go(list[index - 1]);
    return true;
  }

  /// Review → Edit: jumps to [target], then Continue comes back here.
  void edit(AddStudentStep target) {
    _returnToReview = true;
    _error = null;
    _go(target);
  }

  void _go(AddStudentStep target) {
    _step = target;
    if (target == AddStudentStep.review) _returnToReview = false;
    if (target == AddStudentStep.placement) unawaited(loadPlacement());
    notifyListeners();
  }

  /// Something was entered, so closing asks first.
  bool get hasEntered =>
      firstName.text.trim().isNotEmpty ||
      middleName.text.trim().isNotEmpty ||
      lastName.text.trim().isNotEmpty ||
      admissionNumber.text.trim().isNotEmpty ||
      gender != null ||
      dateOfBirth != null ||
      !studentPhoto.isEmpty ||
      hasPersonalDetails ||
      parents.isNotEmpty ||
      schoolClass != null;

  // ── Step 1 · Student ────────────────────────────────────────────────────

  final firstName = TextEditingController();
  final middleName = TextEditingController();
  final lastName = TextEditingController();
  final admissionNumber = TextEditingController();
  StaffGender? gender;
  DateTime? dateOfBirth;
  late DateTime admissionDate;
  PhotoDraft studentPhoto = PhotoDraft(MediaKind.studentPhoto);

  DateTime get today => _today;

  String? get firstNameProblem => firstName.text.trim().isEmpty
      ? null
      : ValidationUtil.validateFirstName(firstName.text.trim());

  String? get lastNameProblem => lastName.text.trim().isEmpty
      ? null
      : ValidationUtil.validateLastName(lastName.text.trim());

  bool get studentValid =>
      firstName.text.trim().isNotEmpty &&
      lastName.text.trim().isNotEmpty &&
      firstNameProblem == null &&
      lastNameProblem == null &&
      gender != null &&
      dateOfBirth != null;

  /// "Chioma Okafor", or "New student" before a name is typed.
  String get studentName {
    final name = '${firstName.text.trim()} ${lastName.text.trim()}'.trim();
    return name.isEmpty ? 'New student' : name;
  }

  /// "Chioma", for "Relationship to Chioma".
  String get studentFirstName {
    final name = firstName.text.trim();
    return name.isEmpty ? 'the student' : name;
  }

  /// The school's admission number pattern, e.g. "KCL/2026/0001".
  String get admissionNumberHint {
    final prefix = school.organization.numberPrefix.trim();
    return prefix.isEmpty
        ? 'Leave blank to generate'
        : '$prefix/${admissionDate.year}/0001';
  }

  void changed() {
    _error = null;
    notifyListeners();
  }

  void pickGender(StaffGender value) {
    gender = value;
    changed();
  }

  void pickDateOfBirth(DateTime value) {
    dateOfBirth = value;
    changed();
  }

  void pickAdmissionDate(DateTime value) {
    admissionDate = value;
    changed();
  }

  // ── Step 2 · Personal details ───────────────────────────────────────────

  final address = TextEditingController();
  final medicalNotes = TextEditingController();
  String? stateOfOrigin;
  String? lga;
  String? bloodGroup;
  String? genotype;

  bool get hasPersonalDetails =>
      address.text.trim().isNotEmpty ||
      medicalNotes.text.trim().isNotEmpty ||
      stateOfOrigin != null ||
      lga != null ||
      bloodGroup != null ||
      genotype != null;

  /// Everything but the medical notes is needed in the app (the database
  /// itself takes them as optional).
  bool get personalValid =>
      stateOfOrigin != null &&
      lga != null &&
      address.text.trim().isNotEmpty &&
      bloodGroup != null &&
      genotype != null;

  /// A different state has different LGAs, so the LGA starts again.
  void pickStateOfOrigin(String value) {
    if (stateOfOrigin != value) lga = null;
    stateOfOrigin = value;
    changed();
  }

  void pickLga(String value) {
    lga = value;
    changed();
  }

  void pickBloodGroup(String value) {
    bloodGroup = value;
    changed();
  }

  void pickGenotype(String value) {
    genotype = value;
    changed();
  }

  /// "Enugu · Nsukka" on the review.
  String get originSummary => [?stateOfOrigin, ?lga].join(' · ');

  /// "O+ · AA" on the review.
  String get healthSummary => [?bloodGroup, ?genotype].join(' · ');

  // ── Photos ──────────────────────────────────────────────────────────────

  /// Acts on what was chosen on the photo options sheet for [draft].
  Future<void> applyPhotoChoice(PhotoDraft draft, AppPhotoChoice choice) async {
    if (choice == AppPhotoChoice.remove) return removePhoto(draft);
    if (choice == AppPhotoChoice.retry) return retryPhoto(draft);
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: choice == AppPhotoChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'AddStudent.pickPhoto',
        showErrorModal: false,
      );
      return;
    }
    if (picked == null) return;
    await usePhotoBytes(draft, await picked.readAsBytes(), path: picked.path);
  }

  /// Shows [bytes] at once and uploads them. A photo this replaces is
  /// deleted from Cloudflare, best effort.
  Future<void> usePhotoBytes(
    PhotoDraft draft,
    Uint8List bytes, {
    String? path,
  }) {
    final old = draft.uploaded;
    draft
      ..generation += 1
      ..bytes = bytes
      ..path = path
      ..failure = null
      ..uploaded = null;
    if (old != null) _deleteQuietly(old.id);
    return _upload(draft);
  }

  /// Uploads a failed photo again.
  Future<void> retryPhoto(PhotoDraft draft) async {
    if (draft.bytes == null || draft.isUploading) return;
    draft.generation += 1;
    await _upload(draft);
  }

  /// Takes the photo off and deletes it from Cloudflare, best effort. An
  /// upload still running is deleted when it lands.
  Future<void> removePhoto(PhotoDraft draft) async {
    final old = draft.uploaded;
    draft.reset();
    notifyListeners();
    if (old != null) _deleteQuietly(old.id);
  }

  Future<void> _upload(PhotoDraft draft) {
    final generation = draft.generation;
    final bytes = draft.bytes!;
    draft.status = AppPhotoStatus.uploading;
    _error = null;
    notifyListeners();
    final future = () async {
      try {
        final media = await _images.uploadImage(
          bytes,
          '${draft.kind.path}-${school.id}.jpg',
          kind: draft.kind,
        );
        if (draft.generation != generation || isDisposed) {
          _deleteQuietly(media.id);
          return;
        }
        draft
          ..uploaded = RegistrationPhoto(id: media.id, url: media.url)
          ..status = AppPhotoStatus.added;
      } catch (error, stackTrace) {
        AppLogger.error(
          'AddStudent photo upload failed',
          error: error,
          stackTrace: stackTrace,
        );
        if (draft.generation != generation) return;
        draft
          ..status = AppPhotoStatus.failed
          ..failure = photoFailure(error);
      } finally {
        if (draft.generation == generation) draft.pending = null;
        if (!isDisposed) notifyListeners();
      }
    }();
    draft.pending = future;
    return future;
  }

  /// The words under a failed photo.
  static String photoFailure(Object error) =>
      error is CloudflareException && error.type == CloudflareError.httpError
      ? "Couldn't upload the photo. Try again."
      : "Couldn't upload the photo. Check your connection.";

  void _deleteQuietly(String id) {
    unawaited(
      _images.deleteImage(id).catchError((Object error) {
        AppLogger.error('AddStudent orphan photo delete failed', error: error);
      }),
    );
  }

  /// Every photo picked in this wizard that isn't on a saved record.
  Iterable<PhotoDraft> get _draftPhotos => [
    studentPhoto,
    for (final parent in parents) ?parent.photo,
    newParentPhoto,
  ];

  /// Closing without registering: deletes the photos uploaded for nothing.
  void discardPhotos() {
    for (final draft in _draftPhotos) {
      final old = draft.uploaded;
      draft.reset();
      if (old != null) _deleteQuietly(old.id);
    }
  }

  // ── Step 3 · Parents ────────────────────────────────────────────────────

  final List<AddedParent> parents = [];
  int _mainIndex = 0;

  /// The main contact's position in [parents]. The first parent added is
  /// main until another is made main.
  int get mainIndex => parents.isEmpty ? -1 : _mainIndex;

  AddedParent? get mainContact => parents.isEmpty ? null : parents[_mainIndex];

  void makeMain(int index) {
    if (index < 0 || index >= parents.length) return;
    _mainIndex = index;
    changed();
  }

  void removeParent(int index) {
    if (index < 0 || index >= parents.length) return;
    final removed = parents.removeAt(index);
    if (removed.photo case final photo?) {
      final old = photo.uploaded;
      photo.reset();
      if (old != null) _deleteQuietly(old.id);
    }
    if (_mainIndex == index) {
      _mainIndex = 0;
    } else if (_mainIndex > index) {
      _mainIndex--;
    }
    changed();
  }

  /// A parent with this id, or these phone digits, is already on the list.
  AddedParent? _alreadyAdded({String? id, String? digits}) {
    for (final parent in parents) {
      if (id != null && parent.match?.id == id) return parent;
      if (digits != null && digits.isNotEmpty && parent.phoneDigits == digits) {
        return parent;
      }
    }
    return null;
  }

  // The Add a parent sheet.

  ParentSheetMode parentMode = ParentSheetMode.search;
  final searchPhone = TextEditingController();
  bool _searching = false;
  String? _parentNotice;
  ParentMatch? foundParent;
  ParentRelationship? sheetRelationship;
  String? _searchedDigits;

  String? newParentTitle;
  final newParentFirstName = TextEditingController();
  final newParentLastName = TextEditingController();
  final newParentPhone = TextEditingController();
  PhotoDraft newParentPhoto = PhotoDraft(MediaKind.parentPhoto);

  /// 9.7c · A new parent's private details, all needed in the app.
  final newParentEmail = TextEditingController();
  final newParentOccupation = TextEditingController();
  final newParentAddress = TextEditingController();

  bool get searching => _searching;

  /// Shown in the sheet: a refusal, or why a parent can't be added.
  String? get parentNotice => _parentNotice;

  static String? phoneProblem(String input) {
    final digits = PhoneFormat.digitsAfterPrefix(input);
    if (digits.isEmpty) return null;
    if (digits.length != 10) {
      return 'Enter an 11-digit number, like 0803 555 0142';
    }
    return null;
  }

  static bool _phoneComplete(String input) =>
      PhoneFormat.digitsAfterPrefix(input).length == 10;

  bool get canSearch => !_searching && _phoneComplete(searchPhone.text);

  bool get canUseFound =>
      !_searching && foundParent != null && sheetRelationship != null;

  String? get newParentFirstNameProblem =>
      newParentFirstName.text.trim().isEmpty
      ? null
      : ValidationUtil.validateFirstName(newParentFirstName.text.trim());

  String? get newParentLastNameProblem => newParentLastName.text.trim().isEmpty
      ? null
      : ValidationUtil.validateLastName(newParentLastName.text.trim());

  /// Shown once something is typed: it must look like an email.
  String? get newParentEmailProblem {
    final value = newParentEmail.text.trim();
    if (value.isEmpty) return null;
    return ValidationUtil.validateEmail(value);
  }

  bool get canAddNewParent =>
      !_searching &&
      newParentFirstName.text.trim().isNotEmpty &&
      newParentLastName.text.trim().isNotEmpty &&
      newParentFirstNameProblem == null &&
      newParentLastNameProblem == null &&
      newParentTitle != null &&
      newParentEmail.text.trim().isNotEmpty &&
      newParentEmailProblem == null &&
      newParentOccupation.text.trim().isNotEmpty &&
      newParentAddress.text.trim().isNotEmpty &&
      _phoneComplete(newParentPhone.text) &&
      sheetRelationship != null &&
      !newParentPhoto.isUploading;

  /// "Ngozi Okafor" for the new parent's initials.
  String get newParentName =>
      '${newParentFirstName.text.trim()} ${newParentLastName.text.trim()}'
          .trim();

  /// Clears the sheet before it opens.
  void startParentSheet() {
    parentMode = ParentSheetMode.search;
    searchPhone.clear();
    _searching = false;
    _parentNotice = null;
    foundParent = null;
    sheetRelationship = null;
    _searchedDigits = null;
    newParentTitle = null;
    newParentFirstName.clear();
    newParentLastName.clear();
    newParentPhone.clear();
    newParentPhoto = PhotoDraft(MediaKind.parentPhoto);
    newParentEmail.clear();
    newParentOccupation.clear();
    newParentAddress.clear();
    notifyListeners();
  }

  /// The sheet closed without adding anyone: the new parent's photo, if one
  /// was uploaded, is deleted.
  void parentSheetDismissed() {
    final old = newParentPhoto.uploaded;
    newParentPhoto.reset();
    if (old != null) _deleteQuietly(old.id);
    newParentPhoto = PhotoDraft(MediaKind.parentPhoto);
  }

  void sheetChanged() {
    _parentNotice = null;
    notifyListeners();
  }

  /// Editing the number after a search starts the search again.
  void searchPhoneChanged() {
    if (parentMode == ParentSheetMode.found) {
      parentMode = ParentSheetMode.search;
      foundParent = null;
      sheetRelationship = null;
      _searchedDigits = null;
    }
    sheetChanged();
  }

  void pickSheetRelationship(ParentRelationship value) {
    sheetRelationship = value;
    sheetChanged();
  }

  void pickNewParentTitle(String value) {
    newParentTitle = value;
    sheetRelationship ??= ParentRelationship.guessFromTitle(value);
    sheetChanged();
  }

  /// Searches the school's parents by the typed phone. Found: the match row.
  /// Not found: the new parent form, with the phone filled in.
  Future<void> findParent() async {
    if (!canSearch) return;
    final digits = PhoneFormat.digitsAfterPrefix(searchPhone.text);
    if (_alreadyAdded(digits: digits) case final added?) {
      _parentNotice = '${added.displayName} is already added.';
      notifyListeners();
      return;
    }
    _searching = true;
    _parentNotice = null;
    notifyListeners();
    try {
      final matches = await _students.findParentsByPhone(
        organizationId: school.id,
        phone: searchPhone.text,
      );
      _searchedDigits = digits;
      if (matches.isEmpty) {
        parentMode = ParentSheetMode.newParent;
        newParentPhone.text = searchPhone.text;
        sheetRelationship = null;
        foundParent = null;
      } else {
        _showFound(matches.first);
      }
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'AddStudent.findParent',
        showErrorModal: false,
      );
      _parentNotice = _messageFor(error, "Couldn't search. Try again.");
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  void _showFound(ParentMatch match) {
    foundParent = match;
    parentMode = ParentSheetMode.found;
    sheetRelationship = ParentRelationship.guessFromTitle(match.title);
    if (_alreadyAdded(id: match.id) case final added?) {
      _parentNotice = '${added.displayName} is already added.';
    }
  }

  /// "Not them? Try another number".
  void tryAnotherNumber() {
    parentMode = ParentSheetMode.search;
    searchPhone.clear();
    foundParent = null;
    sheetRelationship = null;
    _searchedDigits = null;
    _parentNotice = null;
    notifyListeners();
  }

  /// "Use Mrs Okafor": adds the found parent. True when added.
  bool useFoundParent() {
    final match = foundParent;
    final relationship = sheetRelationship;
    if (match == null || relationship == null) return false;
    if (_alreadyAdded(id: match.id, digits: match.phoneDigits)
        case final added?) {
      _parentNotice = '${added.displayName} is already added.';
      notifyListeners();
      return false;
    }
    parents.add(AddedParent.existing(match, relationship));
    changed();
    return true;
  }

  /// "Add parent": adds the new parent. A changed phone is searched again
  /// first, so a parent already in the school is used instead of refused at
  /// Register. True when added.
  Future<bool> addNewParent() async {
    final relationship = sheetRelationship;
    if (!canAddNewParent || relationship == null) return false;
    final digits = PhoneFormat.digitsAfterPrefix(newParentPhone.text);
    if (_alreadyAdded(digits: digits) case final added?) {
      _parentNotice = '${added.displayName} already has this number.';
      notifyListeners();
      return false;
    }
    if (digits != _searchedDigits) {
      _searching = true;
      _parentNotice = null;
      notifyListeners();
      try {
        final matches = await _students.findParentsByPhone(
          organizationId: school.id,
          phone: newParentPhone.text,
        );
        _searchedDigits = digits;
        if (matches.isNotEmpty) {
          final match = matches.first;
          searchPhone.text = newParentPhone.text;
          _showFound(match);
          _parentNotice ??=
              '${match.displayName} is already a parent here with this '
              'number. Use them instead.';
          return false;
        }
      } catch (error, stackTrace) {
        await handleError(
          error,
          stackTrace: stackTrace,
          context: 'AddStudent.addNewParent',
          showErrorModal: false,
        );
        _parentNotice = _messageFor(error, "Couldn't check that number.");
        return false;
      } finally {
        _searching = false;
        notifyListeners();
      }
    }
    parents.add(
      AddedParent.created(
        title: newParentTitle,
        firstName: newParentFirstName.text.trim(),
        lastName: newParentLastName.text.trim(),
        phone: PhoneFormat.stored(newParentPhone.text)!,
        relationship: relationship,
        photo: newParentPhoto,
        email: newParentEmail.text.trim(),
        occupation: newParentOccupation.text.trim(),
        address: newParentAddress.text.trim(),
      ),
    );
    newParentPhoto = PhotoDraft(MediaKind.parentPhoto);
    changed();
    return true;
  }

  // ── Step 4 · Class and arm ──────────────────────────────────────────────

  AcademicSession? _session;
  List<SchoolSection> _sections = const [];
  bool _placementLoaded = false;
  bool _placementLoading = false;
  Object? _placementError;

  SchoolClass? schoolClass;
  ClassArm? arm;

  final _offerings = <String, List<SubjectOffering>>{};
  final _offeringsLoading = <String>{};
  final _offeringsFailed = <String>{};

  AcademicSession? get session => _session;
  bool get placementLoading =>
      _placementLoading || (!_placementLoaded && _placementError == null);
  Object? get placementError => _placementError;
  bool get hasSession => _session != null;
  bool get sessionClosed => _session?.isClosed ?? false;

  /// No current session, or a closed one: the Class step is blocked.
  bool get placementBlocked =>
      _placementLoaded && (!hasSession || sessionClosed);

  /// "2026/27".
  String get sessionName => _session?.name ?? '';

  /// Switched-on classes with at least one switched-on arm, in order (the
  /// same filter as the teaching sheets).
  List<SchoolClass> get classes => [
    for (final section in _sections)
      if (section.isActive)
        for (final each in section.classes)
          if (each.isActive && armsOf(each).isNotEmpty) each,
  ];

  List<ClassArm> armsOf(SchoolClass schoolClass) => [
    for (final each in schoolClass.arms)
      if (each.isActive) each,
  ];

  /// "JSS 1 Gold".
  String get armLabel {
    final chosenClass = schoolClass;
    final chosenArm = arm;
    if (chosenClass == null || chosenArm == null) return '';
    return fullArmName(chosenClass.name, chosenArm.name);
  }

  bool get offeringsReady => arm != null && _offerings.containsKey(arm!.id);
  bool get offeringsLoading =>
      arm != null && _offeringsLoading.contains(arm!.id);
  bool get offeringsFailed => arm != null && _offeringsFailed.contains(arm!.id);

  List<SubjectOffering> get _armOfferings =>
      arm == null ? const [] : _offerings[arm!.id] ?? const [];

  /// What the arm offers as choices, in report-card order.
  List<SubjectOffering> get optionalSubjects => [
    for (final offering in _armOfferings)
      if (!offering.isCompulsory) offering,
  ];

  int get compulsoryCount =>
      _armOfferings.where((offering) => offering.isCompulsory).length;

  /// "9 compulsory subjects · 4 optional to pick next".
  String get armSummary {
    if (offeringsFailed) return "Couldn't load its subjects. Tap to retry.";
    if (!offeringsReady) return 'Checking its subjects…';
    final compulsory = _count(compulsoryCount, 'compulsory subject');
    final optional = optionalSubjects.length;
    return optional == 0
        ? '$compulsory · no optional subjects'
        : '$compulsory · $optional optional to pick next';
  }

  bool get placementValid =>
      _placementLoaded &&
      hasSession &&
      !sessionClosed &&
      arm != null &&
      offeringsReady;

  /// Reads the current session and the classes and arms, once.
  Future<void> loadPlacement() async {
    if (_placementLoaded || _placementLoading) return;
    _placementLoading = true;
    _placementError = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        catalog.session(),
        catalog.sections(),
      ]);
      _session = results[0] as AcademicSession?;
      _sections = results[1] as List<SchoolSection>;
      _placementLoaded = true;
      _dropMissingChoice();
    } catch (error, stackTrace) {
      _placementError = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'AddStudent.loadPlacement',
        showErrorModal: false,
      );
    } finally {
      _placementLoading = false;
      notifyListeners();
    }
  }

  /// After Academic sessions: the session may have changed, so read both
  /// again.
  Future<void> reloadPlacement() async {
    catalog.invalidate();
    _placementLoaded = false;
    await loadPlacement();
  }

  /// A class or arm switched off since it was chosen is let go.
  void _dropMissingChoice() {
    final chosenClass = schoolClass;
    if (chosenClass == null) return;
    final fresh = classes.where((each) => each.id == chosenClass.id);
    if (fresh.isEmpty) {
      schoolClass = null;
      _setArm(null);
      return;
    }
    schoolClass = fresh.first;
    final chosenArm = arm;
    if (chosenArm != null &&
        !armsOf(fresh.first).any((each) => each.id == chosenArm.id)) {
      _setArm(null);
    }
  }

  void pickClass(SchoolClass value) {
    if (schoolClass?.id == value.id) return;
    schoolClass = value;
    _setArm(null);
    changed();
  }

  void pickArm(ClassArm value) {
    if (arm?.id == value.id) return;
    _setArm(value);
    changed();
    unawaited(loadOfferings());
  }

  /// A different arm offers different choices, so they start again.
  void _setArm(ClassArm? value) {
    arm = value;
    chosenSubjectIds.clear();
  }

  /// Reads what the chosen arm offers, once per arm.
  Future<void> loadOfferings() async {
    final chosen = arm;
    if (chosen == null) return;
    final armId = chosen.id;
    if (_offerings.containsKey(armId) || _offeringsLoading.contains(armId)) {
      return;
    }
    _offeringsFailed.remove(armId);
    _offeringsLoading.add(armId);
    notifyListeners();
    try {
      _offerings[armId] = await _subjects.listArmOfferings(
        organizationId: school.id,
        armId: armId,
      );
    } catch (error, stackTrace) {
      _offeringsFailed.add(armId);
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'AddStudent.loadOfferings',
        showErrorModal: false,
      );
    } finally {
      _offeringsLoading.remove(armId);
      notifyListeners();
    }
  }

  // ── Step 5 · Optional subjects ──────────────────────────────────────────

  final Set<String> chosenSubjectIds = {};

  void toggleSubject(String subjectId) {
    if (!chosenSubjectIds.remove(subjectId)) chosenSubjectIds.add(subjectId);
    changed();
  }

  /// The chosen subjects, in report-card order.
  List<SubjectOffering> get chosenSubjects => [
    for (final offering in optionalSubjects)
      if (chosenSubjectIds.contains(offering.subjectId)) offering,
  ];

  /// What everyone in the arm takes, in report-card order (from the arm's
  /// offerings already read; no extra call).
  List<String> get compulsorySubjectNames => [
    for (final offering in _armOfferings)
      if (offering.isCompulsory) offering.name,
  ];

  /// "JSS 1 Gold has 4 to choose from. Tap the ones they will study."
  String get subjectsLead =>
      '$armLabel has ${optionalSubjects.length} to choose from. Tap the ones '
      'they will study.';

  /// "2 of 4 chosen".
  String get chosenCountLabel =>
      '${chosenSubjects.length} of ${optionalSubjects.length} chosen';

  /// "9 subjects".
  String get compulsoryCountLabel => _count(compulsoryCount, 'subject');

  /// "11 subjects in total", above Continue on the subjects step.
  String get subjectTotalLabel =>
      '${_count(compulsoryCount + chosenSubjects.length, 'subject')} in total';

  /// "· 9 compulsory + 2 optional", or "· compulsory only" with none chosen.
  String get subjectTotalDetail {
    final chosen = chosenSubjects.length;
    if (chosen == 0) {
      return compulsoryCount == 0 ? '· none chosen yet' : '· compulsory only';
    }
    if (compulsoryCount == 0) return '· optional only';
    return '· $compulsoryCount compulsory + $chosen optional';
  }

  // ── Step 6 · Review and register ────────────────────────────────────────

  bool _registering = false;
  String? _error;
  RegisteredStudent? _registered;
  bool _parentRefused = false;

  bool get registering => _registering;

  /// Why Register didn't work; everything entered is kept.
  String? get error => _error;

  /// The database refused a new parent whose phone is already in the
  /// school: the Parents step is where to fix it.
  bool get parentRefused => _parentRefused;

  RegisteredStudent? get registered => _registered;

  /// A student was registered while the wizard was open.
  bool get registeredAny => _registeredAny;
  bool _registeredAny = false;

  bool get canRegister =>
      !_registering &&
      studentValid &&
      personalValid &&
      parents.isNotEmpty &&
      placementValid &&
      _registered == null;

  /// What register_student is sent. Null until every step is valid.
  StudentRegistration? buildRegistration() {
    final chosenArm = arm;
    if (!studentValid ||
        !personalValid ||
        parents.isEmpty ||
        chosenArm == null) {
      return null;
    }
    return StudentRegistration(
      organizationId: school.id,
      firstName: firstName.text.trim(),
      middleName: _blankToNull(middleName.text),
      lastName: lastName.text.trim(),
      admissionNumber: _blankToNull(admissionNumber.text),
      gender: gender,
      dateOfBirth: dateOfBirth,
      admissionDate: admissionDate,
      photo: studentPhoto.ready,
      address: _blankToNull(address.text),
      stateOfOrigin: stateOfOrigin,
      lga: lga,
      bloodGroup: bloodGroup,
      genotype: genotype,
      medicalNotes: _blankToNull(medicalNotes.text),
      parents: [
        for (var i = 0; i < parents.length; i++)
          parents[i].toRegistration(isPrimary: i == _mainIndex),
      ],
      armId: chosenArm.id,
      sessionId: _session?.id,
      optionalSubjectIds: [
        for (final offering in chosenSubjects) offering.subjectId,
      ],
    );
  }

  /// Waits for any photo still uploading, then registers the student in one
  /// call. True when registered; otherwise [error] says why.
  Future<bool> register() async {
    if (!canRegister) return false;
    _registering = true;
    _error = null;
    _parentRefused = false;
    notifyListeners();
    try {
      await Future.wait([for (final draft in _draftPhotos) ?draft.pending]);
      if (studentPhoto.hasFailed ||
          parents.any((parent) => parent.photo?.hasFailed ?? false)) {
        _error =
            "A photo didn't upload. Try it again or remove it, then "
            'register.';
        return false;
      }
      final registration = buildRegistration();
      if (registration == null) return false;
      _registered = await _students.registerStudent(registration);
      _registeredAny = true;
      return true;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'AddStudent.register',
        showErrorModal: false,
      );
      _parentRefused = error is ParentAlreadyInSchool;
      _error = _messageFor(error, "Couldn't register them. Try again.");
      return false;
    } finally {
      _registering = false;
      notifyListeners();
    }
  }

  /// "Add another student": starts again at step 1. The session, classes
  /// and arms and what each arm offers stay read.
  void startAnother() {
    firstName.clear();
    middleName.clear();
    lastName.clear();
    admissionNumber.clear();
    gender = null;
    dateOfBirth = null;
    admissionDate = DateTime(_today.year, _today.month, _today.day);
    studentPhoto = PhotoDraft(MediaKind.studentPhoto);
    address.clear();
    medicalNotes.clear();
    stateOfOrigin = null;
    lga = null;
    bloodGroup = null;
    genotype = null;
    parents.clear();
    _mainIndex = 0;
    schoolClass = null;
    _setArm(null);
    _registered = null;
    _error = null;
    _parentRefused = false;
    _returnToReview = false;
    _step = AddStudentStep.student;
    notifyListeners();
  }

  /// "They are in JSS 1 Gold for 2026/27, with 2 optional subjects."
  String get registeredSummary {
    final where = 'They are in $armLabel for $sessionName';
    final chosen = _registered?.subjectIds.length ?? chosenSubjectIds.length;
    if (chosen == 0) return '$where.';
    return '$where, with ${_count(chosen, 'optional subject')}.';
  }

  static String _count(int count, String noun) =>
      count == 1 ? '1 $noun' : '$count ${noun}s';

  static String _messageFor(Object error, String fallback) =>
      error is SupabaseRefusal ? error.message : fallback;

  /// Trimmed, or null when blank (the RPC stores null, not '').
  static String? _blankToNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    firstName.dispose();
    middleName.dispose();
    lastName.dispose();
    admissionNumber.dispose();
    address.dispose();
    medicalNotes.dispose();
    searchPhone.dispose();
    newParentFirstName.dispose();
    newParentLastName.dispose();
    newParentPhone.dispose();
    newParentEmail.dispose();
    newParentOccupation.dispose();
    newParentAddress.dispose();
    super.dispose();
  }
}
