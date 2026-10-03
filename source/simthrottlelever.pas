unit SimThrottleLever;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TSimThrottleLever }
  TSimThrottleLever = class(TSimCustomControl)
  private
    FValue: Extended;
    FMin: Extended;
    FMax: Extended;
    FLeverColor: TColor;
    FOnChange: TNotifyEvent;

    FIsDragging: Boolean;
    FHandleRect: TRectF;

    procedure SetValue(AValue: Extended);
    procedure SetMin(AValue: Extended);
    procedure SetMax(AValue: Extended);
    procedure SetLeverColor(AValue: TColor);
    procedure UpdateValueFromMouse(Y: Integer);
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
    property LeverColor: TColor read FLeverColor write SetLeverColor default clBlack;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 80;
    property Height default 250;
  end;

implementation

{ ==============================================================================
  TSimThrottleLever
  ============================================================================== }

constructor TSimThrottleLever.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 80;
  Height := 250;
  FMin := 0;
  FMax := 100;
  FValue := 0;
  FLeverColor := clBlack;
  FIsDragging := False;
end;

procedure TSimThrottleLever.SetValue(AValue: Extended);
var
  NewVal: Extended;
begin
  NewVal := EnsureRange(AValue, FMin, FMax);
  if FValue = NewVal then Exit;
  FValue := NewVal;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimThrottleLever.SetMin(AValue: Extended);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FValue < FMin then SetValue(FMin);
  InvalidateBackground;
end;

procedure TSimThrottleLever.SetMax(AValue: Extended);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FValue > FMax then SetValue(FMax);
  InvalidateBackground;
end;

procedure TSimThrottleLever.SetLeverColor(AValue: TColor);
begin
  if FLeverColor = AValue then Exit;
  FLeverColor := AValue;
  Invalidate;
end;

procedure TSimThrottleLever.UpdateValueFromMouse(Y: Integer);
var
  NewVal: Extended;
  PadY: Single;
begin
  PadY := 40;
  NewVal := SimMapValue(Y, Height - PadY, PadY, FMin, FMax);
  SetValue(NewVal);
end;

procedure TSimThrottleLever.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsDragging := True;
    UpdateValueFromMouse(Y);
  end;
end;

procedure TSimThrottleLever.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging and Enabled then
    UpdateValueFromMouse(Y);
end;

procedure TSimThrottleLever.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then FIsDragging := False;
end;

procedure TSimThrottleLever.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect, SlotRect: TRectF;
  GradScanner: IBGRAScanner;
  PadY, TickPos: Single;
  i: Integer;
begin
  inherited DrawBackground(ABitmap);

  PadY := 40;
  BaseRect := RectF(2, 2, Width - 2, Height - 2);

  // 1. Panel Logam Dasar
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(150, 150, 150, 255), BGRA(90, 90, 90, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 5, 5, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 5, 5, BGRA(40, 40, 40, 255), 2.0);

  // 2. Lubang Track Slot
  SlotRect := RectF(Width / 2 - 8, PadY - 10, Width / 2 + 8, Height - PadY + 10);
  ABitmap.FillRoundRectAntialias(SlotRect.Left, SlotRect.Top, SlotRect.Right, SlotRect.Bottom, 8, 8, BGRA(15, 15, 15, 255));

  // Inner Shadow Slot
  ABitmap.DrawLineAntialias(SlotRect.Left, SlotRect.Top, SlotRect.Right, SlotRect.Top, BGRA(0, 0, 0, 200), 3);
  ABitmap.DrawLineAntialias(SlotRect.Left, SlotRect.Top, SlotRect.Left, SlotRect.Bottom, BGRA(0, 0, 0, 200), 3);

  // 3. Skala Ticks
  for i := 0 to 10 do
  begin
    TickPos := (Height - PadY) - (i * ((Height - PadY * 2) / 10));
    // Tick Kiri
    ABitmap.DrawLineAntialias(SlotRect.Left - 15, TickPos, SlotRect.Left - 5, TickPos, BGRA(20, 20, 20, 255), 2.0);
    // Garis Putih untuk Max (10)
    if i = 10 then
      ABitmap.DrawLineAntialias(SlotRect.Left - 15, TickPos - 2, SlotRect.Left - 5, TickPos - 2, BGRA(255, 255, 255, 200), 1.0);
  end;

  // Sekrup Panel
  ABitmap.FillEllipseAntialias(12, 12, 3, 3, BGRA(50, 50, 50, 255));
  ABitmap.FillEllipseAntialias(Width - 12, 12, 3, 3, BGRA(50, 50, 50, 255));
  ABitmap.FillEllipseAntialias(12, Height - 12, 3, 3, BGRA(50, 50, 50, 255));
  ABitmap.FillEllipseAntialias(Width - 12, Height - 12, 3, 3, BGRA(50, 50, 50, 255));
end;

procedure TSimThrottleLever.DrawForeground(ABitmap: TBGRABitmap);
var
  PadY, PosCenter, HandleW, HandleH: Single;
  GradScanner: IBGRAScanner;
  C: TBGRAPixel;
  R, G, B: Byte;
  ArmRect: TRectF;
begin
  inherited DrawForeground(ABitmap);

  PadY := 40;
  PosCenter := SimMapValue(FValue, FMin, FMax, Height - PadY, PadY);

  // 1. Batang Tuas (Arm) yang keluar dari slot
  ArmRect := RectF(Width / 2 - 4, PosCenter, Width / 2 + 4, Height - PadY + 10);
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(180, 180, 180, 255), BGRA(50, 50, 50, 255),
    gtLinear, PointF(ArmRect.Left, ArmRect.Top), PointF(ArmRect.Right, ArmRect.Top));
  ABitmap.FillRectAntialias(ArmRect.Left, ArmRect.Top, ArmRect.Right, ArmRect.Bottom, GradScanner);

  // 2. T-Bar Handle
  HandleW := Width * 0.8;
  HandleH := 28.0;
  FHandleRect := RectF(Width / 2 - HandleW / 2, PosCenter - HandleH / 2, Width / 2 + HandleW / 2, PosCenter + HandleH / 2);

  // Drop Shadow
  ABitmap.FillRoundRectAntialias(FHandleRect.Left + 5, FHandleRect.Top + 5, FHandleRect.Right + 5, FHandleRect.Bottom + 5, 6, 6, BGRA(0, 0, 0, 150));

  // Warna Handle
  C := ColorToBGRA(ColorToRGB(FLeverColor));
  R := C.red; G := C.green; B := C.blue;

  GradScanner := TBGRAGradientScanner.Create(
    BGRA(Math.Min(255, R+60), Math.Min(255, G+60), Math.Min(255, B+60), 255),
    BGRA(Math.Max(0, R-50), Math.Max(0, G-50), Math.Max(0, B-50), 255),
    gtLinear, PointF(FHandleRect.Left, FHandleRect.Top), PointF(FHandleRect.Left, FHandleRect.Bottom));

  ABitmap.FillRoundRectAntialias(FHandleRect.Left, FHandleRect.Top, FHandleRect.Right, FHandleRect.Bottom, 6, 6, GradScanner);
  ABitmap.RoundRectAntialias(FHandleRect.Left, FHandleRect.Top, FHandleRect.Right, FHandleRect.Bottom, 6, 6, BGRA(0, 0, 0, 200), 1.5);

  // Highlight Kaca/Plastik mengkilap di bagian atas handle
  ABitmap.FillRoundRectAntialias(FHandleRect.Left + 4, FHandleRect.Top + 2, FHandleRect.Right - 4, FHandleRect.Top + 8, 3, 3, BGRA(255, 255, 255, 60));

  // Grip details (Garis-garis vertikal)
  ABitmap.DrawLineAntialias(FHandleRect.Left + 10, FHandleRect.Top + 5, FHandleRect.Left + 10, FHandleRect.Bottom - 5, BGRA(0, 0, 0, 100), 2.0);
  ABitmap.DrawLineAntialias(FHandleRect.Right - 10, FHandleRect.Top + 5, FHandleRect.Right - 10, FHandleRect.Bottom - 5, BGRA(0, 0, 0, 100), 2.0);
end;

end.
