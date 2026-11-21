import '../../core/utils/format.dart';

class Outlet {
  const Outlet({
    required this.id,
    required this.name,
    required this.brandId,
    required this.areaId,
    this.brandName,
    this.areaName,
    this.latitude,
    this.longitude,
    this.geofenceRadiusM = 150,
    this.timezone = 'Asia/Makassar',
  });

  final String id;
  final String name;
  final String brandId;
  final String areaId;
  final String? brandName;
  final String? areaName;
  final double? latitude;
  final double? longitude;
  final int geofenceRadiusM;
  final String timezone;

  static const select = 'id, name, brand_id, area_id, latitude, longitude, geofence_radius_m, timezone, '
      'brands(name), areas(name)';

  factory Outlet.fromJson(Map<String, dynamic> j) => Outlet(
        id: j['id'] as String,
        name: j['name'] as String,
        brandId: j['brand_id'] as String,
        areaId: j['area_id'] as String,
        brandName: (j['brands'] as Map?)?['name'] as String?,
        areaName: (j['areas'] as Map?)?['name'] as String?,
        latitude: asNum(j['latitude'])?.toDouble(),
        longitude: asNum(j['longitude'])?.toDouble(),
        geofenceRadiusM: (j['geofence_radius_m'] as int?) ?? 150,
        timezone: (j['timezone'] as String?) ?? 'Asia/Makassar',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand_id': brandId,
        'area_id': areaId,
        'brands': {'name': brandName},
        'areas': {'name': areaName},
        'latitude': latitude,
        'longitude': longitude,
        'geofence_radius_m': geofenceRadiusM,
        'timezone': timezone,
      };
}

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    this.phone,
    this.positionId,
    this.positionName,
    this.positionLevel,
    this.departmentName,
    this.outletId,
    this.hireDate,
    this.locale = 'id',
    this.active = true,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String? positionId;
  final String? positionName;
  final int? positionLevel;
  final String? departmentName;
  final String? outletId;
  final DateTime? hireDate;
  final String locale;
  final bool active;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// Days since the first day at work ("Day 12" on the mentor card).
  int? get dayNumber => hireDate == null ? null : DateTime.now().difference(hireDate!).inDays + 1;

  static const select =
      'id, full_name, phone, position_id, outlet_id, hire_date, locale, status, positions(name, level, departments(name))';

  factory Profile.fromJson(Map<String, dynamic> j) {
    final pos = j['positions'] as Map<String, dynamic>?;
    return Profile(
      id: j['id'] as String,
      fullName: j['full_name'] as String,
      phone: j['phone'] as String?,
      positionId: j['position_id'] as String?,
      positionName: pos?['name'] as String?,
      positionLevel: pos?['level'] as int?,
      departmentName: (pos?['departments'] as Map?)?['name'] as String?,
      outletId: j['outlet_id'] as String?,
      hireDate: j['hire_date'] == null ? null : DateTime.parse(j['hire_date'] as String),
      locale: (j['locale'] as String?) ?? 'id',
      active: j['status'] != 'inactive',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'position_id': positionId,
        'outlet_id': outletId,
        'hire_date': hireDate == null ? null : Fmt.isoDate(hireDate!),
        'locale': locale,
        'status': active ? 'active' : 'inactive',
        'positions': positionName == null
            ? null
            : {
                'name': positionName,
                'level': positionLevel,
                'departments': {'name': departmentName}
              },
      };
}

/// One permission granted within a scope (row of my_permissions()).
class Grant {
  const Grant(this.code, this.scopeType, this.scopeId);
  final String code;
  final String scopeType; // group | brand | area | outlet
  final String? scopeId;

  factory Grant.fromJson(Map<String, dynamic> j) =>
      Grant(j['permission_code'] as String, j['scope_type'] as String, j['scope_id'] as String?);

  Map<String, dynamic> toJson() => {'permission_code': code, 'scope_type': scopeType, 'scope_id': scopeId};
}

/// What the app may show. The server checks every action again (PRD R6); this
/// only hides what the server would refuse.
class Session {
  Session({required this.profile, required this.grants, required this.outlets});

  final Profile profile;
  final List<Grant> grants;
  final Map<String, Outlet> outlets;

  Outlet? get outlet => profile.outletId == null ? null : outlets[profile.outletId];

  bool hasAny(String code) => grants.any((g) => g.code == code);

  bool hasGroup(String code) => grants.any((g) => g.code == code && g.scopeType == 'group');

  /// Mirrors app.has_permission(p_perm, p_outlet) in the schema.
  bool can(String code, {String? outletId}) {
    final o = outletId == null ? null : outlets[outletId];
    return grants.any((g) {
      if (g.code != code) return false;
      if (g.scopeType == 'group') return true;
      if (o == null) return false;
      return switch (g.scopeType) {
        'brand' => g.scopeId == o.brandId,
        'area' => g.scopeId == o.areaId,
        'outlet' => g.scopeId == o.id,
        _ => false,
      };
    });
  }

  /// Outlets where the person holds [code], sorted by name.
  List<Outlet> outletsWith(String code) =>
      outlets.values.where((o) => can(code, outletId: o.id)).toList()..sort((a, b) => a.name.compareTo(b.name));

  bool get canFill => hasAny('checklist.fill');
  bool get canLearn => hasAny('learning.take');
  bool get isMentor => hasAny('practical.score') || hasAny('mentor.checkin');
  bool get isAreaManager => hasAny('audit.conduct');
  bool get isOutletManager => !isAreaManager && hasAny('issue.assign');
  bool get isManager => isAreaManager || isOutletManager;
  bool get canViewDashboards => hasAny('dashboard.view');

  /// HQ roles work in the admin web.
  bool get hasAdminAccess => const [
        'org.manage', 'outlet.manage', 'user.manage', 'role.manage', 'module.author', 'module.review',
        'path.manage', 'checklist_template.manage', 'settings.manage', 'audit_log.view',
        'mentor_rating.view_raters', 'dashboard.view',
      ].any(hasAny);

  /// The outlet a manager looks after: their own, else the first in scope.
  Outlet? get managedOutlet {
    if (outlet != null && can('issue.assign', outletId: outlet!.id)) return outlet;
    final list = outletsWith('issue.assign');
    return list.isEmpty ? outlet : list.first;
  }

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'grants': grants.map((g) => g.toJson()).toList(),
        'outlets': outlets.values.map((o) => o.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        profile: Profile.fromJson(j['profile'] as Map<String, dynamic>),
        grants: (j['grants'] as List).map((g) => Grant.fromJson(g as Map<String, dynamic>)).toList(),
        outlets: {
          for (final o in (j['outlets'] as List).map((o) => Outlet.fromJson(o as Map<String, dynamic>))) o.id: o,
        },
      );
}
