unit SimUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, BGRABitmap, BGRABitmapTypes;

{--- Fungsi Bantuan (Helper) Matematika & Geometri ---}

{ Memetakan nilai dari satu rentang asal ke rentang tujuan.
  Sangat berguna untuk mengonversi Nilai Properties (misal: 0 - 100)
  menjadi Sudut Rotasi untuk jarum/knob (misal: 135 - 405 derajat). }
function SimMapValue(const AValue, AMinVal, AMaxVal, AMinTarget, AMaxTarget: Extended): Extended;

{ Menghitung koordinat piksel (X,Y) pada keliling lingkaran berdasarkan sudut.
  Catatan: 0 Derajat = arah jam 3 (Kanan), bergerak searah jarum jam. }
function SimPointOnCircle(const ACenter: TPointF; const ARadius, AAngleDeg: Extended): TPointF;

{ Menormalisasi nilai sudut agar selalu berada di dalam rentang 0.0 hingga 359.9 derajat. }
function SimNormalizeAngle(const AAngleDeg: Extended): Extended;

implementation

function SimMapValue(const AValue, AMinVal, AMaxVal, AMinTarget, AMaxTarget: Extended): Extended;
var
  ClampedValue: Extended;
begin
  // Mencegah error Division By Zero jika nilai min dan max dikonfigurasi sama
  if AMinVal = AMaxVal then
    Exit(AMinTarget);

  // Membatasi nilai input agar tidak melampaui batas yang ditentukan
  if AMinVal < AMaxVal then
    ClampedValue := EnsureRange(AValue, AMinVal, AMaxVal)
  else
    ClampedValue := EnsureRange(AValue, AMaxVal, AMinVal);

  // Rumus interpolasi linear
  Result := (ClampedValue - AMinVal) * (AMaxTarget - AMinTarget) / (AMaxVal - AMinVal) + AMinTarget;
end;

function SimPointOnCircle(const ACenter: TPointF; const ARadius, AAngleDeg: Extended): TPointF;
var
  Rad: Extended;
begin
  // Fungsi Sin/Cos membutuhkan parameter dalam bentuk Radian
  Rad := DegToRad(AAngleDeg);

  Result.X := ACenter.X + (ARadius * Cos(Rad));
  Result.Y := ACenter.Y + (ARadius * Sin(Rad));
end;

function SimNormalizeAngle(const AAngleDeg: Extended): Extended;
begin
  Result := AAngleDeg;

  // Menggunakan looping sederhana yang lebih cepat dari pemanggilan fungsi fmod kompleks
  // untuk nilai sudut standar rotasi UI.
  while Result < 0.0 do
    Result := Result + 360.0;
  while Result >= 360.0 do
    Result := Result - 360.0;
end;

end.

