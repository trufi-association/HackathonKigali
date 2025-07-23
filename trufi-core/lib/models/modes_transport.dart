import 'package:trufi_core/models/othermodel/enums/mode.dart';
import 'package:trufi_core/models/plan_entity.dart';

class ModesTransport {
  final PlanEntity? walkPlan;
  final PlanEntity? bikePlan;
  final PlanEntity? bikeAndPublicPlan;
  final PlanEntity? bikeParkPlan;
  final PlanEntity? carPlan;
  final PlanEntity? carParkPlan;
  final PlanEntity? parkRidePlan;
  final PlanEntity? onDemandTaxiPlan;

  ModesTransport({
    this.walkPlan,
    this.bikePlan,
    this.bikeAndPublicPlan,
    this.bikeParkPlan,
    this.carPlan,
    this.carParkPlan,
    this.parkRidePlan,
    this.onDemandTaxiPlan,
  });

  factory ModesTransport.fromJson(Map<String, dynamic> json) => ModesTransport(
    walkPlan: json["walkPlan"] != null
        ? PlanEntity.fromJson(json["walkPlan"] as Map<String, dynamic>)
        : null,
    bikePlan: json["bikePlan"] != null
        ? PlanEntity.fromJson(json["bikePlan"] as Map<String, dynamic>)
        : null,
    bikeAndPublicPlan: json["bikeAndPublicPlan"] != null
        ? PlanEntity.fromJson(json["bikeAndPublicPlan"] as Map<String, dynamic>)
        : null,
    bikeParkPlan: json["bikeParkPlan"] != null
        ? PlanEntity.fromJson(json["bikeParkPlan"] as Map<String, dynamic>)
        : null,
    carPlan: json["carPlan"] != null
        ? PlanEntity.fromJson(json["carPlan"] as Map<String, dynamic>)
        : null,
    carParkPlan: json["carParkPlan"] != null
        ? PlanEntity.fromJson(json["carParkPlan"] as Map<String, dynamic>)
        : null,
    parkRidePlan: json["parkRidePlan"] != null
        ? PlanEntity.fromJson(json["parkRidePlan"] as Map<String, dynamic>)
        : null,
    onDemandTaxiPlan: json["onDemandTaxiPlan"] != null
        ? PlanEntity.fromJson(json["onDemandTaxiPlan"] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'walkPlan': walkPlan?.toJson(),
    'bikePlan': bikePlan?.toJson(),
    'bikeAndPublicPlan': bikeAndPublicPlan?.toJson(),
    'bikeParkPlan': bikeParkPlan?.toJson(),
    'carPlan': carPlan?.toJson(),
    'carParkPlan': carParkPlan?.toJson(),
    'parkRidePlan': parkRidePlan?.toJson(),
    'onDemandTaxiPlan': onDemandTaxiPlan?.toJson(),
  };

  ModesTransport copyWith({
    PlanEntity? walkPlan,
    PlanEntity? bikePlan,
    PlanEntity? bikeAndPublicPlan,
    PlanEntity? bikeParkPlan,
    PlanEntity? carPlan,
    PlanEntity? carParkPlan,
    PlanEntity? parkRidePlan,
    PlanEntity? onDemandTaxiPlan,
  }) {
    return ModesTransport(
      walkPlan: walkPlan ?? this.walkPlan,
      bikePlan: bikePlan ?? this.bikePlan,
      bikeAndPublicPlan: bikeAndPublicPlan ?? this.bikeAndPublicPlan,
      bikeParkPlan: bikeParkPlan ?? this.bikeParkPlan,
      carPlan: carPlan ?? this.carPlan,
      carParkPlan: carParkPlan ?? this.carParkPlan,
      parkRidePlan: parkRidePlan ?? this.parkRidePlan,
      onDemandTaxiPlan: onDemandTaxiPlan ?? this.onDemandTaxiPlan,
    );
  }

  ModesTransportEntity toModesTransport() {
    return ModesTransportEntity(
      walkPlan: walkPlan?.copyWith(type: 'walkPlan'),
      bikePlan: bikePlan?.copyWith(type: 'bikePlan'),
      bikeAndPublicPlan: bikeAndPublicPlan?.copyWith(type: 'bikeAndPublicPlan'),
      bikeParkPlan: bikeParkPlan?.copyWith(type: 'bikeParkPlan'),
      carPlan: carPlan?.copyWith(type: 'carPlan'),
      carParkPlan: carParkPlan?.copyWith(type: 'carParkPlan'),
      parkRidePlan: parkRidePlan?.copyWith(type: 'parkRidePlan'),
      onDemandTaxiPlan: onDemandTaxiPlan
          ?.copyWith(
            itineraries: onDemandTaxiPlan!.itineraries
                ?.where(
                  (itinerary) => !(itinerary.legs).every(
                    (leg) => leg.mode == Mode.walk.name,
                  ),
                )
                .map((e) => e)
                .toList(),
          )
          .copyWith(type: 'onDemandTaxiPlan'),
    );
  }
}
