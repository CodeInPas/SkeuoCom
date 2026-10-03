unit SimJoystick;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TSimJoystick }
  TSimJoystick = class(TSimCustomControl)
  private
    FXValue: Extended;
    FYValue: Extended;
    FAutoReturn: Boolean;
    FStickColor: TColor;
    FBaseColor: TColor;
    FOnChange: TNotifyEvent;

    FIsDragging: Boolean;

    procedure SetXValue(AValue: Extended);
    procedure SetYValue(AValue: Extended);
    procedure SetAutoReturn(AValue: Boolean);
    procedure SetStickColor(AValue: TColor);
    procedure SetBaseColor(AValue: TColor);
    procedure UpdateValuesFromMouse(X, Y: Integer);
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;

    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property XValue: Extended read FXValue write SetXValue; // -100 to 100
    property YValue: Extended read FYValue write SetYValue; // -100 to 100
    property AutoReturn: Boolean read FAutoReturn write SetAutoReturn default True;
    property StickColor: TColor read FStickColor write SetStickColor default clRed;
    property BaseColor: TColor read FBaseColor write SetBaseColor default $00202020;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 150;
    property Height default 150;
  end;

implementation

{ ==============================================================================
  TSimJoystick
  ============================================================================== }

constructor TSimJoystick.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 150;
  Height := 150;
  FXValue := 0;
  FYValue := 0;
  FAutoReturn := True;
  FStickColor := clRed;
  FBaseColor := $00202020;
  FIsDragging := False;
end;

procedure TSimJoystick.SetXValue(AValue: Extended);
var
  NewVal: Extended;
begin
  NewVal := EnsureRange(AValue, -100, 100);
  if FXValue = NewVal then Exit;
  FXValue := NewVal;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimJoystick.SetYValue(AValue: Extended);
var
  NewVal: Extended;
begin
  NewVal := EnsureRange(AValue, -100, 100);
  if FYValue = NewVal then Exit;
  FYValue := NewVal;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimJoystick.SetAutoReturn(AValue: Boolean);
begin
  if FAutoReturn = AValue then Exit;
  FAutoReturn := AValue;
  if FAutoReturn and not FIsDragging then
  begin
    FXValue := 0;
    FYValue := 0;
    Invalidate;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TSimJoystick.SetStickColor(AValue: TColor);
begin
  if FStickColor = AValue then Exit;
  FStickColor := AValue;
  Invalidate;
end;

procedure TSimJoystick.SetBaseColor(AValue: TColor);
begin
  if FBaseColor = AValue then Exit;
  FBaseColor := AValue;
  InvalidateBackground;
end;

procedure TSimJoystick.UpdateValuesFromMouse(X, Y: Integer);
var
  CX, CY, MaxR, DX, DY, Dist, Angle: Single;
  NewX, NewY: Extended;
begin
  CX := Width / 2;
  CY := Height / 2;
  MaxR := Min(CX, CY) - 30; // 30 is approx knob radius + padding

  DX := X - CX;
  DY := Y - CY;
  Dist := Hypot(DX, DY);

  // Constrain to circular boundary
  if Dist > MaxR then
  begin
    Angle := ArcTan2(DY, DX);
    DX := Cos(Angle) * MaxR;
    DY := Sin(Angle) * MaxR;
  end;

  NewX := (DX / MaxR) * 100;
  NewY := (DY / MaxR) * -100; // Invert Y so up is positive

  if (FXValue <> NewX) or (FYValue <> NewY) then
  begin
    FXValue := EnsureRange(NewX, -100, 100);
    FYValue := EnsureRange(NewY, -100, 100);
    Invalidate;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TSimJoystick.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsDragging := True;
    UpdateValuesFromMouse(X, Y);
  end;
end;

procedure TSimJoystick.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging and Enabled then
    UpdateValuesFromMouse(X, Y);
end;

procedure TSimJoystick.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FIsDragging := False;
    if FAutoReturn then
    begin
      FXValue := 0;
      FYValue := 0;
      Invalidate;
      if Assigned(FOnChange) then FOnChange(Self);
    end;
  end;
end;

procedure TSimJoystick.MouseLeave;
begin
  inherited MouseLeave;
  if FIsDragging and FAutoReturn then
  begin
    FIsDragging := False;
    FXValue := 0;
    FYValue := 0;
    Invalidate;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TSimJoystick.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius, InnerRadius: Single;
  GradScanner: IBGRAScanner;
  BaseC: TBGRAPixel;
begin
  inherited DrawBackground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;
  Radius := Min(CX, CY) - 4;
  InnerRadius := Radius * 0.8;

  // Outer Bezel / Housing
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(90, 90, 90, 255), BGRA(30, 30, 30, 255),
    gtLinear, PointF(CX - Radius, CY - Radius), PointF(CX + Radius, CY + Radius));
  ABitmap.FillEllipseAntialias(CX, CY, Radius, Radius, GradScanner);
  ABitmap.EllipseAntialias(CX, CY, Radius, Radius, BGRA(0, 0, 0, 255), 2.0);

  // Inner Bowl (Concave)
  BaseC := ColorToBGRA(ColorToRGB(FBaseColor));
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(0, 0, 0, 255), BaseC,
    gtLinear, PointF(CX - InnerRadius, CY - InnerRadius), PointF(CX + InnerRadius, CY + InnerRadius));
  ABitmap.FillEllipseAntialias(CX, CY, InnerRadius, InnerRadius, GradScanner);
  ABitmap.EllipseAntialias(CX, CY, InnerRadius, InnerRadius, BGRA(0, 0, 0, 200), 3.0);

  // Center alignment rings
  ABitmap.EllipseAntialias(CX, CY, InnerRadius * 0.5, InnerRadius * 0.5, BGRA(255, 255, 255, 20), 1.0);
  ABitmap.DrawLineAntialias(CX, CY - InnerRadius, CX, CY + InnerRadius, BGRA(255, 255, 255, 15), 1.0);
  ABitmap.DrawLineAntialias(CX - InnerRadius, CY, CX + InnerRadius, CY, BGRA(255, 255, 255, 15), 1.0);
end;

procedure TSimJoystick.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, MaxR, KnobRadius, KnobX, KnobY: Single;
  C: TBGRAPixel;
  R, G, B: Byte;
  GradScanner: IBGRAScanner;
begin
  inherited DrawForeground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;
  KnobRadius := 20;
  MaxR := Min(CX, CY) - KnobRadius - 10;

  KnobX := CX + (FXValue / 100) * MaxR;
  KnobY := CY - (FYValue / 100) * MaxR; // Invert Y back to pixel space

  // 1. Draw Stick Shaft (from center to knob)
  ABitmap.DrawLineAntialias(CX, CY, KnobX, KnobY, BGRA(50, 50, 50, 255), 8.0);
  ABitmap.DrawLineAntialias(CX, CY, KnobX, KnobY, BGRA(150, 150, 150, 255), 4.0);

  // 2. Knob Drop Shadow
  ABitmap.FillEllipseAntialias(KnobX + 4, KnobY + 6, KnobRadius, KnobRadius, BGRA(0, 0, 0, 150));

  // 3. Knob Sphere
  C := ColorToBGRA(ColorToRGB(FStickColor));
  R := C.red; G := C.green; B := C.blue;

  GradScanner := TBGRAGradientScanner.Create(
    BGRA(Min(255, R+80), Min(255, G+80), Min(255, B+80), 255),
    BGRA(Max(0, R-50), Max(0, G-50), Max(0, B-50), 255),
    gtLinear, PointF(KnobX - KnobRadius, KnobY - KnobRadius), PointF(KnobX + KnobRadius, KnobY + KnobRadius));

  ABitmap.FillEllipseAntialias(KnobX, KnobY, KnobRadius, KnobRadius, GradScanner);
  ABitmap.EllipseAntialias(KnobX, KnobY, KnobRadius, KnobRadius, BGRA(0, 0, 0, 200), 1.0);

  // 4. Specular Highlight (Glossy Plastic reflection)
  ABitmap.FillEllipseAntialias(KnobX - KnobRadius*0.3, KnobY - KnobRadius*0.3,
                               KnobRadius*0.4, KnobRadius*0.4,
                               BGRA(255, 255, 255, 90));
end;

end.
