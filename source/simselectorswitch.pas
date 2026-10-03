unit SimSelectorSwitch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TSimSelectorSwitch }
  TSimSelectorSwitch = class(TSimCustomControl)
  private
    FPositions: Integer;
    FPositionIndex: Integer;
    FKnobColor: TColor;
    FIndicatorColor: TColor;
    FOnChange: TNotifyEvent;

    procedure SetPositions(AValue: Integer);
    procedure SetPositionIndex(AValue: Integer);
    procedure SetKnobColor(AValue: TColor);
    procedure SetIndicatorColor(AValue: TColor);
    function AngleToIndex(X, Y: Integer): Integer;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;

    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Positions: Integer read FPositions write SetPositions default 5;
    property PositionIndex: Integer read FPositionIndex write SetPositionIndex default 0;
    property KnobColor: TColor read FKnobColor write SetKnobColor default $00303030;
    property IndicatorColor: TColor read FIndicatorColor write SetIndicatorColor default clWhite;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 80;
    property Height default 80;
  end;

implementation

{ ==============================================================================
  TSimSelectorSwitch
  ============================================================================== }

constructor TSimSelectorSwitch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 80;
  Height := 80;
  FPositions := 5;
  FPositionIndex := 0;
  FKnobColor := $00303030; // Dark Gray
  FIndicatorColor := clWhite;
end;

procedure TSimSelectorSwitch.SetPositions(AValue: Integer);
begin
  if AValue < 2 then AValue := 2;
  if FPositions = AValue then Exit;
  FPositions := AValue;
  if FPositionIndex >= FPositions then
    SetPositionIndex(FPositions - 1);
  InvalidateBackground;
end;

procedure TSimSelectorSwitch.SetPositionIndex(AValue: Integer);
var
  NewIdx: Integer;
begin
  NewIdx := EnsureRange(AValue, 0, FPositions - 1);
  if FPositionIndex = NewIdx then Exit;
  FPositionIndex := NewIdx;
  Invalidate; // Memperbarui orientasi knob (Foreground)
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimSelectorSwitch.SetKnobColor(AValue: TColor);
begin
  if FKnobColor = AValue then Exit;
  FKnobColor := AValue;
  Invalidate;
end;

procedure TSimSelectorSwitch.SetIndicatorColor(AValue: TColor);
begin
  if FIndicatorColor = AValue then Exit;
  FIndicatorColor := AValue;
  Invalidate;
end;

function TSimSelectorSwitch.AngleToIndex(X, Y: Integer): Integer;
var
  CX, CY, A, AdjA, Step: Single;
begin
  CX := Width / 2;
  CY := Height / 2;

  // Hitung sudut klik dari pusat
  A := RadToDeg(ArcTan2(Y - CY, X - CX));
  if A < 0 then A := A + 360;

  // Sudut awal (Index 0) adalah 135 derajat. Offset koordinat.
  AdjA := A - 135;
  if AdjA < 0 then AdjA := AdjA + 360;

  Step := 270 / (FPositions - 1);

  // Tangani klik di area "Dead Zone" (Bawah, antara 45 sampai 135 derajat)
  if AdjA > 270 then
  begin
    if AdjA < (270 + 45) then
      Result := FPositions - 1
    else
      Result := 0;
  end
  else
    Result := Round(AdjA / Step);

  Result := EnsureRange(Result, 0, FPositions - 1);
end;

procedure TSimSelectorSwitch.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
    SetPositionIndex(AngleToIndex(X, Y));
end;

procedure TSimSelectorSwitch.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if (ssLeft in Shift) and Enabled then
    SetPositionIndex(AngleToIndex(X, Y));
end;

procedure TSimSelectorSwitch.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius, TickOuter, TickInner, StepAngle, A, RRad: Single;
  i: Integer;
  P1, P2: TPointF;
begin
  inherited DrawBackground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;
  Radius := Min(CX, CY) - 4;

  TickOuter := Radius;
  TickInner := Radius * 0.8;

  // Cincin penanda dasar (opsional)
  ABitmap.EllipseAntialias(CX, CY, TickOuter + 2, TickOuter + 2, BGRA(0, 0, 0, 50), 1.0);

  // Menggambar titik/garis penanda posisi (Ticks)
  StepAngle := 270 / (FPositions - 1);
  for i := 0 to FPositions - 1 do
  begin
    A := 135 + (i * StepAngle);
    if A >= 360 then A := A - 360;

    RRad := DegToRad(A);
    P1 := PointF(CX + (Cos(RRad) * TickInner), CY + (Sin(RRad) * TickInner));
    P2 := PointF(CX + (Cos(RRad) * TickOuter), CY + (Sin(RRad) * TickOuter));

    // Garis tebal dan bayangannya
    ABitmap.DrawLineAntialias(P1.X, P1.Y + 1, P2.X, P2.Y + 1, BGRA(255, 255, 255, 100), 2.5);
    ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(30, 30, 30, 255), 2.5);
  end;
end;

procedure TSimSelectorSwitch.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, KnobRadius, A, RRad: Single;
  C: TBGRAPixel;
  R, G, B: Byte;
  GradScanner: IBGRAScanner;
  IndColor: TBGRAPixel;
  IndP1, IndP2: TPointF;
begin
  inherited DrawForeground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;
  KnobRadius := Min(CX, CY) * 0.65;

  // 1. Bayangan Knob
  ABitmap.FillEllipseAntialias(CX + 3, CY + 4, KnobRadius, KnobRadius, BGRA(0, 0, 0, 150));

  // 2. Base Knob (Gradient Metalik/Plastik)
  C := ColorToBGRA(ColorToRGB(FKnobColor));
  R := C.red; G := C.green; B := C.blue;

  GradScanner := TBGRAGradientScanner.Create(
    BGRA(Min(255, R+40), Min(255, G+40), Min(255, B+40), 255),
    BGRA(Max(0, R-40), Max(0, G-40), Max(0, B-40), 255),
    gtLinear, PointF(CX - KnobRadius, CY - KnobRadius), PointF(CX + KnobRadius, CY + KnobRadius));

  ABitmap.FillEllipseAntialias(CX, CY, KnobRadius, KnobRadius, GradScanner);
  ABitmap.EllipseAntialias(CX, CY, KnobRadius, KnobRadius, BGRA(0, 0, 0, 255), 1.5);

  // Inner Bevel (Kesan 3D)
  ABitmap.EllipseAntialias(CX, CY, KnobRadius * 0.9, KnobRadius * 0.9, BGRA(255, 255, 255, 30), 1.5);

  // Detail Tengah (Poros/Sekrup)
  ABitmap.FillEllipseAntialias(CX, CY, KnobRadius * 0.3, KnobRadius * 0.3, BGRA(Max(0, R-60), Max(0, G-60), Max(0, B-60), 255));
  ABitmap.EllipseAntialias(CX, CY, KnobRadius * 0.3, KnobRadius * 0.3, BGRA(0, 0, 0, 200), 1.0);

  // 3. Garis Indikator Penunjuk
  A := 135 + (FPositionIndex * (270 / (FPositions - 1)));
  if A >= 360 then A := A - 360;

  RRad := DegToRad(A);
  IndColor := ColorToBGRA(ColorToRGB(FIndicatorColor));

  IndP1 := PointF(CX + (Cos(RRad) * (KnobRadius * 0.4)), CY + (Sin(RRad) * (KnobRadius * 0.4)));
  IndP2 := PointF(CX + (Cos(RRad) * (KnobRadius * 0.85)), CY + (Sin(RRad) * (KnobRadius * 0.85)));

  // Bayangan Indikator
  ABitmap.DrawLineAntialias(IndP1.X, IndP1.Y + 1, IndP2.X, IndP2.Y + 1, BGRA(0, 0, 0, 180), 3.0);
  // Garis Indikator
  ABitmap.DrawLineAntialias(IndP1.X, IndP1.Y, IndP2.X, IndP2.Y, IndColor, 3.0);
end;

end.
