unit SimInputs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  TKnobDragMode = (kmLinear, kmCircular);
  TSwitchState = (ssOff, ssOn);

  { TKnob }
  TKnob = class(TSimCustomControl)
  private
    FValue: Extended;
    FMin: Extended;
    FMax: Extended;
    FMinAngle: Extended;
    FMaxAngle: Extended;
    FDragMode: TKnobDragMode;
    FOnChange: TNotifyEvent;

    FIsDragging: Boolean;
    FLastMouseY: Integer;

    procedure SetValue(AValue: Extended);
    procedure SetMin(AValue: Extended);
    procedure SetMax(AValue: Extended);
    function AngleToValue(AAngle: Extended): Extended;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Value: Extended read FValue write SetValue;
    property Min: Extended read FMin write SetMin;
    property Max: Extended read FMax write SetMax;
    property MinAngle: Extended read FMinAngle write FMinAngle;
    property MaxAngle: Extended read FMaxAngle write FMaxAngle;
    property DragMode: TKnobDragMode read FDragMode write FDragMode default kmLinear;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 80;
    property Height default 80;
  end;

  { TSimToggleSwitch }
  TSimToggleSwitch = class(TSimCustomControl)
  private
    FState: TSwitchState;
    FOnChange: TNotifyEvent;
    procedure SetState(AValue: TSwitchState);
  protected
    procedure Click; override;
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property State: TSwitchState read FState write SetState default ssOff;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 40;
    property Height default 80;
  end;

implementation

{ ==============================================================================
  TKnob
  ============================================================================== }

constructor TKnob.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 80;
  Height := 80;
  FMin := 0;
  FMax := 100;
  FValue := 0;
  FMinAngle := 135;  // Kiri bawah
  FMaxAngle := 405;  // Kanan bawah
  FDragMode := kmLinear;
  FIsDragging := False;
end;

procedure TKnob.SetValue(AValue: Extended);
var
  NewVal: Extended;
begin
  NewVal := EnsureRange(AValue, FMin, FMax);
  if FValue = NewVal then Exit;
  FValue := NewVal;
  Invalidate; // Gambar ulang foreground (jarum putar)
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TKnob.SetMin(AValue: Extended);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FValue < FMin then SetValue(FMin);
  Invalidate;
end;

procedure TKnob.SetMax(AValue: Extended);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FValue > FMax then SetValue(FMax);
  Invalidate;
end;

function TKnob.AngleToValue(AAngle: Extended): Extended;
var
  NormAngle, NormMin, NormMax: Extended;
begin
  // Logika kompleks untuk memetakan sudut melingkar ke nilai linear
  NormAngle := SimNormalizeAngle(AAngle);
  NormMin := SimNormalizeAngle(FMinAngle);
  NormMax := SimNormalizeAngle(FMaxAngle);

  if FMaxAngle > 360 then
  begin
    if NormAngle < NormMin then NormAngle := NormAngle + 360;
  end;

  Result := SimMapValue(NormAngle, FMinAngle, FMaxAngle, FMin, FMax);
end;

procedure TKnob.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CX, CY: Single;
  AngleRad, AngleDeg: Extended;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsDragging := True;
    FLastMouseY := Y;

    if FDragMode = kmCircular then
    begin
      CX := Width / 2;
      CY := Height / 2;
      AngleRad := ArcTan2(Y - CY, X - CX);
      AngleDeg := RadToDeg(AngleRad);
      SetValue(AngleToValue(AngleDeg));
    end;
  end;
end;

procedure TKnob.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  CX, CY: Single;
  AngleRad, AngleDeg: Extended;
  DeltaY: Integer;
  ValRange, Step: Extended;
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging and Enabled then
  begin
    if FDragMode = kmLinear then
    begin
      DeltaY := FLastMouseY - Y; // Geser ke atas = positif
      if DeltaY <> 0 then
      begin
        ValRange := FMax - FMin;
        Step := ValRange * 0.01; // Sensitivitas 1% per piksel
        SetValue(FValue + (DeltaY * Step));
        FLastMouseY := Y;
      end;
    end
    else // kmCircular
    begin
      CX := Width / 2;
      CY := Height / 2;
      AngleRad := ArcTan2(Y - CY, X - CX);
      AngleDeg := RadToDeg(AngleRad);
      SetValue(AngleToValue(AngleDeg));
    end;
  end;
end;

procedure TKnob.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then FIsDragging := False;
end;

procedure TKnob.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius: Single;
  i: Integer;
  TickAngle: Extended;
  P1, P2: TPointF;
begin
  inherited DrawBackground(ABitmap);
  CX := Width / 2;
  CY := Height / 2;
  Radius := Math.Min(CX, CY) - 4;

  // Gambar Skala/Ticks di sekeliling Knob
  for i := 0 to 10 do
  begin
    TickAngle := FMinAngle + (i * ((FMaxAngle - FMinAngle) / 10));
    P1 := SimPointOnCircle(PointF(CX, CY), Radius, TickAngle);
    P2 := SimPointOnCircle(PointF(CX, CY), Radius * 0.85, TickAngle);
    ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(50, 50, 50, 255), 2.0);
  end;
end;

procedure TKnob.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, KnobRadius, BezelRadius, IndAngle: Single;
  GradScanner: IBGRAScanner;
  IndP1, IndP2: TPointF;
begin
  inherited DrawForeground(ABitmap);
  CX := Width / 2;
  CY := Height / 2;
  BezelRadius := Math.Min(CX, CY) * 0.8;
  KnobRadius := BezelRadius * 0.9;
  if KnobRadius <= 0 then Exit;

  // 1. Drop shadow knob
  ABitmap.FillEllipseAntialias(CX, CY + 3, BezelRadius, BezelRadius, BGRA(0, 0, 0, 120));

  // 2. Bezel luar metalik
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(200, 200, 200, 255), BGRA(80, 80, 80, 255),
    gtLinear, PointF(CX - BezelRadius, CY - BezelRadius), PointF(CX + BezelRadius, CY + BezelRadius));
  ABitmap.FillEllipseAntialias(CX, CY, BezelRadius, BezelRadius, GradScanner);

  // 3. Badan utama knob (agak cembung)
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(160, 160, 160, 255), BGRA(40, 40, 40, 255),
    gtLinear, PointF(CX, CY - KnobRadius), PointF(CX, CY + KnobRadius));
  ABitmap.FillEllipseAntialias(CX, CY, KnobRadius, KnobRadius, GradScanner);

  // 4. Indikator (Garis penunjuk)
  IndAngle := SimMapValue(FValue, FMin, FMax, FMinAngle, FMaxAngle);
  IndP1 := SimPointOnCircle(PointF(CX, CY), KnobRadius * 0.3, IndAngle);
  IndP2 := SimPointOnCircle(PointF(CX, CY), KnobRadius * 0.8, IndAngle);

  // Garis indikator cekung (shadow + highlight)
  ABitmap.DrawLineAntialias(IndP1.X + 1, IndP1.Y + 1, IndP2.X + 1, IndP2.Y + 1, BGRA(255, 255, 255, 100), 3.0);
  ABitmap.DrawLineAntialias(IndP1.X, IndP1.Y, IndP2.X, IndP2.Y, BGRA(30, 30, 30, 255), 3.0);
end;

{ ==============================================================================
  TSimToggleSwitch
  ============================================================================== }

constructor TSimToggleSwitch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 40;
  Height := 80;
  FState := ssOff;
end;

procedure TSimToggleSwitch.SetState(AValue: TSwitchState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimToggleSwitch.Click;
begin
  inherited Click;
  if Enabled then
  begin
    if FState = ssOff then SetState(ssOn)
    else SetState(ssOff);
  end;
end;

procedure TSimToggleSwitch.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect: TRectF;
  GradScanner: IBGRAScanner;
  SlotW, SlotH, SlotX, SlotY: Single;
begin
  inherited DrawBackground(ABitmap);

  // Base Plate (Plat Besi)
  BaseRect := RectF(2, 2, Width - 2, Height - 2);
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(210, 210, 210, 255), BGRA(140, 140, 140, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));

  // PERBAIKAN: Dipecah menjadi dua perintah gambar untuk kompatibilitas
  // Pertama isi (fill) dengan gradien
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, GradScanner);
  // Kedua gambar garis luar (border) solid
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, BGRA(100, 100, 100, 255), 1);

  // Baut pemasangan (Opsional, detail kecil)
  ABitmap.FillEllipseAntialias(Width / 2, 8, 2, 2, BGRA(50, 50, 50, 255));
  ABitmap.FillEllipseAntialias(Width / 2, Height - 8, 2, 2, BGRA(50, 50, 50, 255));

  // Slot tuas
  SlotW := Width * 0.25;
  SlotH := Height * 0.4;
  SlotX := (Width - SlotW) / 2;
  SlotY := (Height - SlotH) / 2;
  ABitmap.FillRectAntialias(SlotX, SlotY, SlotX + SlotW, SlotY + SlotH, BGRA(20, 20, 20, 255));
  // Inner shadow slot
  ABitmap.DrawLineAntialias(SlotX, SlotY, SlotX + SlotW, SlotY, BGRA(0, 0, 0, 200), 2);
  ABitmap.DrawLineAntialias(SlotX, SlotY, SlotX, SlotY + SlotH, BGRA(0, 0, 0, 200), 2);
end;

procedure TSimToggleSwitch.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, LeverW, LeverH: Single;
  LeverRect: TRectF;
  GradScanner: IBGRAScanner;
begin
  inherited DrawForeground(ABitmap);
  CX := Width / 2;
  CY := Height / 2;
  LeverW := Width * 0.4;
  LeverH := Height * 0.35;

  if FState = ssOn then
  begin
    // Tuas arah ke atas
    LeverRect := RectF(CX - LeverW/2, CY - LeverH, CX + LeverW/2, CY + LeverW/2);

    // Shadow Tuas On
    ABitmap.FillRectAntialias(LeverRect.Left + 5, LeverRect.Top + 10, LeverRect.Right + 5, LeverRect.Bottom, BGRA(0, 0, 0, 100));

    GradScanner := TBGRAGradientScanner.Create(
      BGRA(230, 230, 230, 255), BGRA(120, 120, 120, 255),
      gtLinear, PointF(LeverRect.Left, LeverRect.Top), PointF(LeverRect.Left, LeverRect.Bottom));
    ABitmap.FillRectAntialias(LeverRect.Left, LeverRect.Top, LeverRect.Right, LeverRect.Bottom, GradScanner);
  end
  else
  begin
    // Tuas arah ke bawah
    LeverRect := RectF(CX - LeverW/2, CY - LeverW/2, CX + LeverW/2, CY + LeverH);

    // Shadow Tuas Off
    ABitmap.FillRectAntialias(LeverRect.Left + 5, LeverRect.Top, LeverRect.Right + 5, LeverRect.Bottom + 5, BGRA(0, 0, 0, 100));

    GradScanner := TBGRAGradientScanner.Create(
      BGRA(230, 230, 230, 255), BGRA(120, 120, 120, 255),
      gtLinear, PointF(LeverRect.Left, LeverRect.Bottom), PointF(LeverRect.Left, LeverRect.Top));
    ABitmap.FillRectAntialias(LeverRect.Left, LeverRect.Top, LeverRect.Right, LeverRect.Bottom, GradScanner);
  end;

  // Engsel tuas (Pivot)
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(150, 150, 150, 255), BGRA(50, 50, 50, 255),
    gtLinear, PointF(CX - LeverW/2, CY - LeverW/2), PointF(CX + LeverW/2, CY + LeverW/2));
  ABitmap.FillEllipseAntialias(CX, CY, LeverW/2, LeverW/2, GradScanner);
end;

end.
