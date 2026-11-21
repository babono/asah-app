import 'package:asah/features/session/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app hides what the server would refuse; these mirror
/// app.has_permission() scope rules in the schema.
void main() {
  const outletA = Outlet(id: 'oA', name: 'Outlet A', brandId: 'b1', areaId: 'a1');
  const outletB = Outlet(id: 'oB', name: 'Outlet B', brandId: 'b1', areaId: 'a2');
  const outletC = Outlet(id: 'oC', name: 'Outlet C', brandId: 'b2', areaId: 'a2');
  const profile = Profile(id: 'u1', fullName: 'Putu Ayu', outletId: 'oA');

  Session session(List<Grant> grants) =>
      Session(profile: profile, grants: grants, outlets: {for (final o in [outletA, outletB, outletC]) o.id: o});

  test('outlet scope covers only that outlet', () {
    final s = session([const Grant('issue.assign', 'outlet', 'oA')]);
    expect(s.can('issue.assign', outletId: 'oA'), isTrue);
    expect(s.can('issue.assign', outletId: 'oB'), isFalse);
    expect(s.can('issue.assign'), isFalse, reason: 'no outlet means group scope is needed');
  });

  test('area and brand scopes follow the outlet', () {
    final s = session([const Grant('audit.conduct', 'area', 'a2'), const Grant('checklist.view', 'brand', 'b1')]);
    expect(s.outletsWith('audit.conduct').map((o) => o.id), ['oB', 'oC']);
    expect(s.outletsWith('checklist.view').map((o) => o.id), ['oA', 'oB']);
  });

  test('group scope covers everything', () {
    final s = session([const Grant('dashboard.view', 'group', null)]);
    expect(s.can('dashboard.view'), isTrue);
    expect(s.outletsWith('dashboard.view'), hasLength(3));
    expect(s.hasGroup('dashboard.view'), isTrue);
  });

  test('default roles map to the right home tabs', () {
    final staff = session([
      const Grant('learning.take', 'outlet', 'oA'),
      const Grant('checklist.fill', 'outlet', 'oA'),
    ]);
    expect(staff.isMentor, isFalse);
    expect(staff.isManager, isFalse);

    final mentor = session([const Grant('learning.take', 'outlet', 'oA'), const Grant('practical.score', 'outlet', 'oA')]);
    expect(mentor.isMentor, isTrue);

    final outletManager = session([const Grant('issue.assign', 'outlet', 'oA')]);
    expect(outletManager.isOutletManager, isTrue);
    expect(outletManager.managedOutlet?.id, 'oA');

    final areaManager = session([const Grant('issue.assign', 'area', 'a2'), const Grant('audit.conduct', 'area', 'a2')]);
    expect(areaManager.isAreaManager, isTrue);
    expect(areaManager.isOutletManager, isFalse);
  });

  test('session survives the offline cache round trip', () {
    final s = session([const Grant('issue.view', 'area', 'a1')]);
    final copy = Session.fromJson(s.toJson());
    expect(copy.profile.fullName, 'Putu Ayu');
    expect(copy.can('issue.view', outletId: 'oA'), isTrue);
    expect(copy.can('issue.view', outletId: 'oC'), isFalse);
  });
}
