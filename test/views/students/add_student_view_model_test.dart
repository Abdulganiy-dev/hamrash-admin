import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/students/parent_relationship.dart';
import 'package:hamrash_admin/api/models/students/student_registration.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/widgets/app_photo_field.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';

import 'add_student_fakes.dart';

final _bytes = Uint8List.fromList([1, 2, 3]);

void main() {
  late Fakes fakes;
  late AddStudentViewModel model;

  setUp(() {
    fakes = Fakes();
    model = fakes.model();
  });

  /// Adds Ngozi (found by phone) as the mother.
  Future<void> addNgozi() async {
    fakes.students.matches = const [ngozi];
    model.startParentSheet();
    model.searchPhone.text = '08035550142';
    await model.findParent();
    expect(model.parentMode, ParentSheetMode.found);
    expect(model.useFoundParent(), isTrue);
  }

  /// Adds a new father with a fresh number.
  Future<void> addNewFather({String phone = '08051112233'}) async {
    fakes.students.matches = const [];
    model.startParentSheet();
    model.searchPhone.text = phone;
    await model.findParent();
    expect(model.parentMode, ParentSheetMode.newParent);
    model.pickNewParentTitle('Mr');
    model.newParentFirstName.text = 'Emeka';
    model.newParentLastName.text = 'Okafor';
    fillNewParentDetails(model);
    expect(await model.addNewParent(), isTrue);
  }

  /// Gets to the review with JSS 1 Gold and French chosen.
  Future<void> reachReview() async {
    fillStudent(model);
    model.next();
    expect(model.step, AddStudentStep.personal);
    fillPersonal(model);
    model.next();
    await addNgozi();
    model.next();
    await model.loadPlacement();
    model.pickClass(model.classes.single);
    model.pickArm(model.armsOf(model.classes.single).first);
    await model.loadOfferings();
    model.next();
    model.toggleSubject('french');
    model.next();
    expect(model.step, AddStudentStep.review);
  }

  group('step gating', () {
    test('student step needs names, gender and date of birth', () {
      expect(model.canContinue, isFalse);
      model.firstName.text = 'Chioma';
      model.lastName.text = 'Okafor';
      expect(model.canContinue, isFalse);
      model.pickGender(StaffGender.female);
      expect(model.canContinue, isFalse);
      model.pickDateOfBirth(DateTime(2015, 3, 14));
      expect(model.canContinue, isTrue);

      model.next();
      expect(model.step, AddStudentStep.personal);
      expect(model.canContinue, isFalse, reason: 'nothing filled yet');
      fillPersonal(model);
      expect(model.canContinue, isTrue, reason: 'medical notes are optional');
      model.next();
      expect(model.step, AddStudentStep.parents);
      expect(model.canContinue, isFalse, reason: 'no parent yet');
    });

    test('six steps in order, five without optional subjects', () {
      expect(model.steps, [
        AddStudentStep.student,
        AddStudentStep.personal,
        AddStudentStep.parents,
        AddStudentStep.placement,
        AddStudentStep.subjects,
        AddStudentStep.review,
      ]);
      expect(model.stepCount, 6);
      expect(
        model.stepEyebrow(AddStudentStep.personal),
        'Step 2 of 6 · Personal details',
      );
      expect(
        model.stepEyebrow(AddStudentStep.parents),
        'Step 3 of 6 · Parents',
      );
    });

    test('back walks to the previous step and refuses on the first', () {
      expect(model.back(), isFalse);
      fillStudent(model);
      model.next();
      expect(model.back(), isTrue);
      expect(model.step, AddStudentStep.student);
      expect(model.firstName.text, 'Chioma', reason: 'typed text is kept');
    });

    test('the class step waits for the arm and what it offers', () async {
      fillStudent(model);
      model.next();
      fillPersonal(model);
      model.next();
      await addNgozi();
      model.next();
      await model.loadPlacement();
      expect(model.canContinue, isFalse);
      model.pickClass(model.classes.single);
      expect(model.canContinue, isFalse);
      model.pickArm(model.armsOf(model.classes.single).first);
      expect(model.canContinue, isFalse, reason: 'offerings still loading');
      await model.loadOfferings();
      expect(model.canContinue, isTrue);
      expect(model.compulsoryCount, 1);
      expect(model.optionalSubjects.map((s) => s.subjectId), [
        'french',
        'music',
      ]);
      expect(
        model.armSummary,
        '1 compulsory subject · 2 optional to pick next',
      );
    });

    test('the session and classes are read once', () async {
      await model.loadPlacement();
      await model.loadPlacement();
      expect(fakes.structure.sessionReads, 1);
      expect(fakes.structure.structureReads, 1);
    });

    test('no current session blocks the class step', () async {
      fakes.structure.session = null;
      await model.loadPlacement();
      expect(model.placementBlocked, isTrue);
      expect(model.placementValid, isFalse);
    });

    test('a closed session blocks the class step', () async {
      fakes.structure.session = session(closedAt: DateTime(2027, 8));
      await model.loadPlacement();
      expect(model.placementBlocked, isTrue);
    });
  });

  group('parents', () {
    test('the first parent is main and Make main switches it', () async {
      await addNgozi();
      await addNewFather();
      expect(model.parents.length, 2);
      expect(model.mainIndex, 0);
      model.makeMain(1);
      expect(model.mainIndex, 1);

      final registration = _registrationAfter(model);
      expect(
        registration.parents.where((p) => p.isPrimaryContact).length,
        1,
        reason: 'exactly one main contact',
      );
      expect(registration.parents[1].isPrimaryContact, isTrue);
    });

    test('removing the main contact makes the first one main', () async {
      await addNgozi();
      await addNewFather();
      model.makeMain(1);
      model.removeParent(1);
      expect(model.mainIndex, 0);
    });

    test('the same parent cannot be added twice', () async {
      await addNgozi();
      model.startParentSheet();
      model.searchPhone.text = '+2348035550142';
      await model.findParent();
      expect(model.parentNotice, contains('already added'));
      expect(model.parents.length, 1);
      expect(fakes.students.searches, 1, reason: 'no second search');
    });

    test('a new parent cannot reuse an added phone number', () async {
      await addNewFather();
      model.startParentSheet();
      model.searchPhone.text = '8051112233';
      await model.findParent();
      expect(model.parentNotice, contains('already added'));
      expect(model.parents.length, 1);
    });

    test('a found match picks a relationship from the title', () async {
      fakes.students.matches = const [ngozi];
      model.startParentSheet();
      model.searchPhone.text = '08035550142';
      await model.findParent();
      expect(model.foundParent?.caption, 'Parent of Tobenna');
      expect(model.sheetRelationship, ParentRelationship.mother);
      model.tryAnotherNumber();
      expect(model.parentMode, ParentSheetMode.search);
      expect(model.searchPhone.text, isEmpty);
    });

    test('a changed number on the new parent form is searched again and '
        'steers to the parent found', () async {
      fakes.students.matches = const [];
      model.startParentSheet();
      model.searchPhone.text = '08051112233';
      await model.findParent();
      model.pickNewParentTitle('Mrs');
      model.newParentFirstName.text = 'Ngozi';
      model.newParentLastName.text = 'Okafor';
      fillNewParentDetails(model);
      model.pickSheetRelationship(ParentRelationship.mother);
      model.newParentPhone.text = '08035550142';
      fakes.students.matches = const [ngozi];

      expect(await model.addNewParent(), isFalse);
      expect(model.parentMode, ParentSheetMode.found);
      expect(model.foundParent?.id, 'ngozi');
      expect(model.parentNotice, contains('Use them instead'));
      expect(model.parents, isEmpty);
    });
  });

  group('subjects', () {
    test('changing the arm clears the chosen subjects', () async {
      await model.loadPlacement();
      final jss1 = model.classes.single;
      model.pickClass(jss1);
      model.pickArm(model.armsOf(jss1).first);
      await model.loadOfferings();
      model.toggleSubject('french');
      expect(model.chosenSubjectIds, {'french'});

      model.pickArm(model.armsOf(jss1).last);
      expect(model.chosenSubjectIds, isEmpty);
    });

    test('an arm with no optional subjects skips the subjects step', () async {
      fillStudent(model);
      model.next();
      fillPersonal(model);
      model.next();
      await addNgozi();
      model.next();
      await model.loadPlacement();
      final jss1 = model.classes.single;
      model.pickClass(jss1);
      model.pickArm(model.armsOf(jss1).last); // Blue: compulsory only
      await model.loadOfferings();

      expect(model.skipsSubjects, isTrue);
      expect(model.stepCount, 5);
      expect(model.eyebrow, 'Step 4 of 5 · Class');
      model.next();
      expect(model.step, AddStudentStep.review);
      expect(model.eyebrow, 'Step 5 of 5 · Review');
    });

    test('the subjects step copy comes from the loaded offerings', () async {
      await model.loadPlacement();
      final jss1 = model.classes.single;
      model.pickClass(jss1);
      model.pickArm(model.armsOf(jss1).first);
      await model.loadOfferings();
      final reads = fakes.subjects.reads;

      expect(model.compulsorySubjectNames, ['Maths']);
      expect(model.compulsoryCountLabel, '1 subject');
      expect(
        model.subjectsLead,
        'JSS 1 Gold has 2 to choose from. Tap the ones they will study.',
      );
      expect(model.chosenCountLabel, '0 of 2 chosen');
      expect(model.subjectTotalLabel, '1 subject in total');
      expect(model.subjectTotalDetail, '· compulsory only');

      model.toggleSubject('french');
      expect(model.chosenCountLabel, '1 of 2 chosen');
      expect(model.subjectTotalLabel, '2 subjects in total');
      expect(model.subjectTotalDetail, '· 1 compulsory + 1 optional');

      model.toggleSubject('music');
      expect(model.subjectTotalLabel, '3 subjects in total');
      expect(model.subjectTotalDetail, '· 1 compulsory + 2 optional');

      model.toggleSubject('french');
      expect(model.subjectTotalLabel, '2 subjects in total');
      expect(model.subjectTotalDetail, '· 1 compulsory + 1 optional');
      // Names come from the offerings already read.
      expect(fakes.subjects.reads, reads);
    });

    test('each arm is read once', () async {
      await model.loadPlacement();
      final jss1 = model.classes.single;
      model.pickClass(jss1);
      model.pickArm(model.armsOf(jss1).first);
      await model.loadOfferings();
      model.pickArm(model.armsOf(jss1).last);
      await model.loadOfferings();
      model.pickArm(model.armsOf(jss1).first);
      await model.loadOfferings();
      expect(fakes.subjects.reads, 2);
    });
  });

  group('register', () {
    test('sends one call shaped like register_student', () async {
      await reachReview();
      await addNewFatherFromReview(model, fakes);
      expect(await model.register(), isTrue);

      expect(fakes.students.registrations.length, 1);
      final params = fakes.students.registrations.single.toParams();
      expect(params['p_organization_id'], 'school');
      expect(params['p_first_name'], 'Chioma');
      expect(params['p_last_name'], 'Okafor');
      expect(params['p_arm_id'], 'gold');
      expect(params['p_session_id'], 'session');
      expect(params['p_optional_subject_ids'], ['french']);
      expect(params['p_gender'], 'female');
      expect(params['p_date_of_birth'], '2015-03-14');
      expect(params['p_admission_date'], '2026-09-07');
      expect(params['p_admission_number'], isNull);
      expect(params['p_middle_name'], isNull);
      expect(params['p_address'], '12 Ogui Road, Enugu');
      expect(params['p_state_of_origin'], 'Enugu');
      expect(params['p_lga'], 'Nsukka');
      expect(params['p_blood_group'], 'O+');
      expect(params['p_genotype'], 'AA');
      expect(params.containsKey('p_medical_notes'), isTrue);
      expect(params['p_medical_notes'], isNull, reason: 'blank means null');
      expect(params['p_parents'], [
        {
          'parent_id': 'ngozi',
          'relationship': 'mother',
          'is_primary_contact': true,
        },
        {
          'title': 'Mr',
          'first_name': 'Emeka',
          'last_name': 'Okafor',
          'phone': '+2348051112233',
          'photo_id': null,
          'photo_url': null,
          'email': 'emeka@example.com',
          'occupation': 'Civil engineer',
          'address': '5 Zik Avenue, Enugu',
          'relationship': 'father',
          'is_primary_contact': false,
        },
      ]);
      expect(model.registered?.admissionNumber, 'KCL/2026/0042');
      expect(model.registeredAny, isTrue);
    });

    test('a refusal is shown and everything is kept', () async {
      await reachReview();
      fakes.students.registerError = const ParentAlreadyInSchool(
        'Ngozi Okafor is already a parent in this school with phone '
        '08035550142. Choose them as an existing parent instead of adding '
        'them again',
      );
      expect(await model.register(), isFalse);
      expect(model.error, contains('already a parent'));
      expect(model.parentRefused, isTrue);
      expect(model.step, AddStudentStep.review);
      expect(model.firstName.text, 'Chioma');
      expect(model.parents.length, 1);
      expect(model.chosenSubjectIds, {'french'});

      fakes.students.registerError = const SupabaseRefusal(
        'Admission number KCL/1 is already used in this school.',
      );
      expect(await model.register(), isFalse);
      expect(model.error, contains('Admission number'));
      expect(model.parentRefused, isFalse);
    });

    test('personal details reach the call trimmed', () async {
      await reachReview();
      model.edit(AddStudentStep.personal);
      expect(model.step, AddStudentStep.personal);
      model.address.text = '  12 Ogui Road, Enugu  ';
      model.medicalNotes.text = '   ';
      model.next();
      expect(model.step, AddStudentStep.review);
      expect(model.originSummary, 'Enugu · Nsukka');
      expect(model.healthSummary, 'O+ · AA');

      expect(await model.register(), isTrue);
      final params = fakes.students.registrations.single.toParams();
      expect(params['p_address'], '12 Ogui Road, Enugu');
      expect(params['p_state_of_origin'], 'Enugu');
      expect(params['p_lga'], 'Nsukka');
      expect(params['p_blood_group'], 'O+');
      expect(params['p_genotype'], 'AA');
      expect(params['p_medical_notes'], isNull, reason: 'blank means null');
    });

    test('medical notes are sent trimmed when given', () async {
      await reachReview();
      model.medicalNotes.text = '  Peanut allergy ';
      expect(await model.register(), isTrue);
      final params = fakes.students.registrations.single.toParams();
      expect(params['p_medical_notes'], 'Peanut allergy');
    });

    test('Add parent waits for title, email, occupation and address', () async {
      fakes.students.matches = const [];
      model.startParentSheet();
      model.searchPhone.text = '08051112233';
      await model.findParent();
      model.newParentFirstName.text = 'Emeka';
      model.newParentLastName.text = 'Okafor';
      model.pickSheetRelationship(ParentRelationship.father);
      expect(model.canAddNewParent, isFalse, reason: 'no title');
      model.pickNewParentTitle('Mr');
      expect(model.canAddNewParent, isFalse, reason: 'no email and so on');

      model.newParentEmail.text = 'emeka@example.com';
      model.newParentOccupation.text = 'Civil engineer';
      expect(model.canAddNewParent, isFalse, reason: 'no address');
      model.newParentAddress.text = '   ';
      expect(model.canAddNewParent, isFalse, reason: 'blank address');
      model.newParentAddress.text = '5 Zik Avenue';
      expect(model.canAddNewParent, isTrue);

      model.newParentEmail.text = 'not an email';
      expect(model.newParentEmailProblem, isNotNull);
      expect(model.canAddNewParent, isFalse, reason: 'a bad email blocks');
      model.newParentEmail.text = '';
      expect(model.newParentEmailProblem, isNull, reason: 'no error yet');
      expect(model.canAddNewParent, isFalse);
    });

    test('a new parent\'s details go in p_parents trimmed; an existing '
        'parent has no new keys', () async {
      await reachReview();
      fakes.students.matches = const [];
      model.startParentSheet();
      model.searchPhone.text = '08051112233';
      await model.findParent();
      model.pickNewParentTitle('Mr');
      model.newParentFirstName.text = 'Emeka';
      model.newParentLastName.text = 'Okafor';
      model.newParentEmail.text = ' emeka@example.com ';
      model.newParentOccupation.text = ' Civil engineer ';
      model.newParentAddress.text = ' 5 Zik Avenue ';
      expect(await model.addNewParent(), isTrue);

      expect(await model.register(), isTrue);
      final params = fakes.students.registrations.single.toParams();
      final parents = params['p_parents']! as List;
      final father = parents[1] as Map<String, Object?>;
      expect(father['email'], 'emeka@example.com');
      expect(father['occupation'], 'Civil engineer');
      expect(father['address'], '5 Zik Avenue');
      final mother = parents[0] as Map<String, Object?>;
      expect(mother.keys, ['parent_id', 'relationship', 'is_primary_contact']);

      model.startParentSheet();
      expect(model.newParentEmail.text, isEmpty);
      expect(model.newParentOccupation.text, isEmpty);
      expect(model.newParentAddress.text, isEmpty);
    });

    test('Continue on personal details waits for the five', () {
      fillStudent(model);
      model.next();
      expect(model.step, AddStudentStep.personal);
      expect(model.canContinue, isFalse);
      model.next();
      expect(model.step, AddStudentStep.personal, reason: 'blocked');

      model
        ..pickStateOfOrigin('Enugu')
        ..pickLga('Nsukka')
        ..pickBloodGroup('O+');
      model.address.text = '12 Ogui Road';
      expect(model.canContinue, isFalse, reason: 'no genotype');
      model.pickGenotype('AA');
      model.address.text = '  ';
      expect(model.canContinue, isFalse, reason: 'blank address');
      model.address.text = '12 Ogui Road';
      expect(model.canContinue, isTrue, reason: 'notes are optional');
      model.pickStateOfOrigin('Lagos');
      expect(model.canContinue, isFalse, reason: 'new state clears the LGA');
      model.pickLga('Ikeja');
      model.next();
      expect(model.step, AddStudentStep.parents);
    });

    test('a new state of origin clears the LGA', () {
      model
        ..pickStateOfOrigin('Enugu')
        ..pickLga('Nsukka')
        ..pickStateOfOrigin('Enugu');
      expect(model.lga, 'Nsukka', reason: 'same state keeps it');
      model.pickStateOfOrigin('Lagos');
      expect(model.lga, isNull);
    });

    test('personal details alone make closing ask first', () {
      expect(model.hasEntered, isFalse);
      model.pickGenotype('AS');
      expect(model.hasEntered, isTrue);
    });

    test('Edit jumps back and Continue returns to the review', () async {
      await reachReview();
      model.edit(AddStudentStep.student);
      expect(model.step, AddStudentStep.student);
      model.next();
      expect(model.step, AddStudentStep.review);
    });

    test('waits for a photo still uploading and sends it', () async {
      await reachReview();
      fakes.images.instant = false;
      final upload = model.usePhotoBytes(model.studentPhoto, _bytes);
      expect(model.studentPhoto.status, AppPhotoStatus.uploading);

      final registering = model.register();
      fakes.images.finishAll();
      await upload;
      expect(await registering, isTrue);
      final params = fakes.students.registrations.single.toParams();
      expect(params['p_photo_id'], 'img1');
      expect(params['p_photo_url'], 'https://img/img1');
    });

    test(
      'a failed photo stops Register until it is retried or removed',
      () async {
        await reachReview();
        fakes.images.fail = true;
        await model.usePhotoBytes(model.studentPhoto, _bytes);
        expect(model.studentPhoto.status, AppPhotoStatus.failed);
        expect(await model.register(), isFalse);
        expect(model.error, contains("didn't upload"));
        expect(fakes.students.registrations, isEmpty);

        await model.removePhoto(model.studentPhoto);
        expect(await model.register(), isTrue);
      },
    );

    test('Add another student starts again at step 1', () async {
      await reachReview();
      model
        ..pickStateOfOrigin('Enugu')
        ..pickLga('Nsukka')
        ..pickBloodGroup('O+')
        ..pickGenotype('AA');
      model.address.text = '12 Ogui Road';
      model.medicalNotes.text = 'Asthma';
      expect(await model.register(), isTrue);
      model.startAnother();
      expect(model.step, AddStudentStep.student);
      expect(model.firstName.text, isEmpty);
      expect(model.parents, isEmpty);
      expect(model.arm, isNull);
      expect(model.registered, isNull);
      expect(model.hasPersonalDetails, isFalse);
    });

    test(
      'the registered page reads the placement and the subject split',
      () async {
        await reachReview();
        expect(await model.register(), isTrue);
        expect(model.registeredPlacement, 'JSS 1 Gold · 2026/27');
        expect(model.registeredSubjects, '1 core · 1 optional');
      },
    );

    test('with no optional subjects the split is just the core', () async {
      fillStudent(model);
      model.next();
      fillPersonal(model);
      model.next();
      await addNgozi();
      model.next();
      await model.loadPlacement();
      final jss1 = model.classes.single;
      model.pickClass(jss1);
      model.pickArm(model.armsOf(jss1).last); // Blue: compulsory only
      await model.loadOfferings();
      model.next(); // Subjects is skipped.
      expect(model.step, AddStudentStep.review);

      expect(await model.register(), isTrue);
      expect(model.registeredPlacement, 'JSS 1 Blue · 2026/27');
      expect(model.registeredSubjects, '1 core');
    });
  });

  group('photos', () {
    test('replacing a photo deletes the old upload', () async {
      await model.usePhotoBytes(model.studentPhoto, _bytes);
      expect(model.studentPhoto.uploaded?.id, 'img1');
      await model.usePhotoBytes(model.studentPhoto, _bytes);
      await pumpEventQueue();
      expect(fakes.images.deleted, ['img1']);
      expect(model.studentPhoto.uploaded?.id, 'img2');
    });

    test('removing a photo deletes it', () async {
      await model.usePhotoBytes(model.studentPhoto, _bytes);
      await model.removePhoto(model.studentPhoto);
      await pumpEventQueue();
      expect(fakes.images.deleted, ['img1']);
      expect(model.studentPhoto.status, AppPhotoStatus.empty);
    });

    test('an upload that lands after removal is deleted', () async {
      fakes.images.instant = false;
      final upload = model.usePhotoBytes(model.studentPhoto, _bytes);
      await model.removePhoto(model.studentPhoto);
      fakes.images.finishAll();
      await upload;
      await pumpEventQueue();
      expect(fakes.images.deleted, ['img1']);
      expect(model.studentPhoto.status, AppPhotoStatus.empty);
    });

    test(
      'a new parent sheet closed without adding deletes its photo',
      () async {
        model.startParentSheet();
        await model.usePhotoBytes(model.newParentPhoto, _bytes);
        model.parentSheetDismissed();
        await pumpEventQueue();
        expect(fakes.images.deleted, ['img1']);
      },
    );

    test('discarding the wizard deletes every uploaded photo', () async {
      await model.usePhotoBytes(model.studentPhoto, _bytes);
      model.discardPhotos();
      await pumpEventQueue();
      expect(fakes.images.deleted, ['img1']);
    });
  });
}

/// Adds the new father from the review (Edit → Parents → back to review).
Future<void> addNewFatherFromReview(
  AddStudentViewModel model,
  Fakes fakes,
) async {
  fakes.students.matches = const [];
  model.startParentSheet();
  model.searchPhone.text = '08051112233';
  await model.findParent();
  model.pickNewParentTitle('Mr');
  model.newParentFirstName.text = 'Emeka';
  model.newParentLastName.text = 'Okafor';
  fillNewParentDetails(model);
  expect(await model.addNewParent(), isTrue);
}

StudentRegistration _registrationAfter(AddStudentViewModel model) {
  fillStudent(model);
  return StudentRegistration(
    organizationId: 'school',
    firstName: 'Chioma',
    lastName: 'Okafor',
    parents: [
      for (var i = 0; i < model.parents.length; i++)
        model.parents[i].toRegistration(isPrimary: i == model.mainIndex),
    ],
    armId: 'gold',
  );
}
