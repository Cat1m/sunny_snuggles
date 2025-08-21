import 'quiz_enums.dart';

class UserGuess {
  final TempBand temp;
  final RainChoice rain;
  final WindBand wind;
  final UvBand? uv; // optional

  const UserGuess({
    required this.temp,
    required this.rain,
    required this.wind,
    this.uv,
  });

  Map<String, dynamic> toJson() => {
    'temp': temp.name,
    'rain': rain.name,
    'wind': wind.name,
    'uv': uv?.name,
  };

  factory UserGuess.fromJson(Map<String, dynamic> json) => UserGuess(
    temp: TempBand.values.firstWhere((e) => e.name == json['temp']),
    rain: RainChoice.values.firstWhere((e) => e.name == json['rain']),
    wind: WindBand.values.firstWhere((e) => e.name == json['wind']),
    uv: json['uv'] == null
        ? null
        : UvBand.values.firstWhere((e) => e.name == json['uv']),
  );
}
