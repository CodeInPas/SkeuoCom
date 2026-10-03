unit SimGauges;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, Math,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TCircularGauge }
  TCircularGauge = class(TSimGraphicControl)
  private
    FValue: Extended;
    FMin: Extended;
    FMax: Extended;
    FMinAngle: Extended;
    FMaxAngle: Extended;
    FCaption: String;
    FUnits: String;
    FMajorTicks: Integer;
    FMinorTicks: Integer;
    procedure SetValue(AValue: Extended);
    procedure SetMin(AValue: Extended);
    procedure SetMax(AValue: Extended);
    procedure SetCaption(const AValue: String);
    procedure SetUnits(const AValue: String);
    procedure SetMajorTicks(AValue: Integer);
  protected
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
    property Caption: String read FCaption write SetCaption;
    property Units: String read FUnits write SetUnits;
    property MajorTicks: Integer read FMajorTicks write SetMajorTicks default 10;
    property MinorTicks: Integer read FMinorTicks write FMinorTicks default 5;

    property Align;
    property Anchors;
    property Visible;
    property Font;
    property Width default 150;
    property Height default 150;
  end;

  TLinearOrientation = (loVertical, loHorizontal);

  { TLinearGauge }
  TLinearGauge = class(TSimGraphicControl)
  private
    FValue: Extended;
    FMin: Extended;
    FMax: Extended;
    FOrientation: TLinearOrientation;
    FBarColor: TColor;
    procedure SetValue(AValue: Extended);
    procedure SetMin(AValue: Extended);
    procedure SetMax(AValue: Extended);
    procedure SetOrientation(AValue: TLinearOrientation);
    procedure SetBarColor(AValue: TColor);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Value: Extended read FValue write SetValue;
    property Min: Extended read FMin write SetMin;
    property Max: Extended read FMax write SetMax;
    property Orientation: TLinearOrientation read FOrientation write SetOrientation default loVertical;
    property BarColor: TColor read FBarColor write SetBarColor default clHighLight;

    property Align;
    property Anchors;
    property Visible;
    property Font;
    property Width default 50;
    property Height default 200;
  end;

  { TVuMeter }
  TVuMeter = class(TSimGraphicControl)
  private
    FValue: Extended;
    FMin: Extended;
    FMax: Extended;
    procedure SetValue(AValue: Extended);
    procedure SetMin(AValue: Extended);
    procedure SetMax(AValue: Extended);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Value: Extended read FValue write SetValue;
    property Min: Extended read FMin write SetMin;
    property Max: Extended read FMax write SetMax;

    property Align;
    property Anchors;
    property Visible;
    property Width default 150;
    property Height default 100;
  end;

implementation

{ ==============================================================================
  TCircularGauge
  ============================================================================== }

constructor TCircularGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 150;
  Height := 150;
  FMin := 0;
  FMax := 100;
  FValue := 0;
  FMinAngle := 135;
  FMaxAngle := 405;
  FMajorTicks := 10;
  FMinorTicks := 5;
  FCaption := 'RPM';
  FUnits := 'x1000';
  Font.Name := 'Arial';
  Font.Style := [fsBold];
end;

procedure TCircularGauge.SetValue(AValue: Extended);
var
  NewVal: Extended;
begin
  NewVal := EnsureRange(AValue, FMin, FMax);
  if FValue = NewVal then Exit;
  FValue := NewVal;
  Invalidate;
end;

procedure TCircularGauge.SetMin(AValue: Extended);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FValue < FMin then SetValue(FMin);
  InvalidateBackground;
end;

procedure TCircularGauge.SetMax(AValue: Extended);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FValue > FMax then SetValue(FMax);
  InvalidateBackground;
end;

procedure TCircularGauge.SetCaption(const AValue: String);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  InvalidateBackground;
end;

procedure TCircularGauge.SetUnits(const AValue: String);
begin
  if FUnits = AValue then Exit;
  FUnits := AValue;
  InvalidateBackground;
end;

procedure TCircularGauge.SetMajorTicks(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if FMajorTicks = AValue then Exit;
  FMajorTicks := AValue;
  InvalidateBackground;
end;

procedure TCircularGauge.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius, InnerRadius: Single;
  GradScanner: IBGRAScanner;
  i, j, TotalMinor: Integer;
  TickAngle, ValStep, CurVal: Extended;
  P1, P2: TPointF;
  S: String;
  Tw, Th: Integer;
begin
  inherited DrawBackground(ABitmap);
  CX := Width / 2;
  CY := Height / 2;
  Radius := Math.Min(CX, CY) - 4;
  if Radius <= 0 then Exit;

  // Drop Shadow
  ABitmap.FillEllipseAntialias(CX, CY + 3, Radius, Radius, BGRA(0, 0, 0, 100));

  // Bezel Luar
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(230, 230, 230, 255), BGRA(90, 90, 90, 255),
    gtLinear, PointF(CX - Radius, CY - Radius), PointF(CX + Radius, CY + Radius));
  ABitmap.FillEllipseAntialias(CX, CY, Radius, Radius, GradScanner);

  // Latar Dalam (Faceplate)
  InnerRadius := Radius * 0.85;
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(255, 255, 255, 255), BGRA(220, 220, 210, 255),
    gtLinear, PointF(CX - InnerRadius, CY + InnerRadius), PointF(CX + InnerRadius, CY - InnerRadius));
  ABitmap.FillEllipseAntialias(CX, CY, InnerRadius, InnerRadius, GradScanner);

  // Inner Shadow pada Faceplate (Perbaikan: Menggunakan EllipseAntialias)
  ABitmap.EllipseAntialias(CX, CY, InnerRadius, InnerRadius, BGRA(0, 0, 0, 150), 2.0);

  // Gambar Skala & Angka
  ABitmap.FontHeight := Round(InnerRadius * 0.15);
  ABitmap.FontStyle := Font.Style;
  ABitmap.FontName := Font.Name;
  ABitmap.FontAntialias := True;

  ValStep := (FMax - FMin) / FMajorTicks;
  TotalMinor := FMajorTicks * FMinorTicks;

  for i := 0 to FMajorTicks do
  begin
    TickAngle := FMinAngle + (i * ((FMaxAngle - FMinAngle) / FMajorTicks));

    // Major Tick Line
    P1 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.95, TickAngle);
    P2 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.80, TickAngle);
    ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(0, 0, 0, 255), 3.0);

    // Text Label
    CurVal := FMin + (i * ValStep);
    S := IntToStr(Round(CurVal));
    Tw := ABitmap.TextSize(S).cx;
    Th := ABitmap.TextSize(S).cy;
    P2 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.60, TickAngle);
    ABitmap.TextOut(P2.X - (Tw/2), P2.Y - (Th/2), S, BGRA(0, 0, 0, 255));
  end;

  // Minor Ticks
  for j := 0 to TotalMinor do
  begin
    if j mod FMinorTicks = 0 then Continue; // Skip posisi Major Tick
    TickAngle := FMinAngle + (j * ((FMaxAngle - FMinAngle) / TotalMinor));
    P1 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.95, TickAngle);
    P2 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.88, TickAngle);
    ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(50, 50, 50, 255), 1.0);
  end;

  // Caption & Units
  ABitmap.FontHeight := Round(InnerRadius * 0.18);
  Tw := ABitmap.TextSize(FCaption).cx;
  ABitmap.TextOut(CX - (Tw/2), CY + InnerRadius * 0.2, FCaption, BGRA(0, 0, 0, 200));

  ABitmap.FontHeight := Round(InnerRadius * 0.12);
  Tw := ABitmap.TextSize(FUnits).cx;
  ABitmap.TextOut(CX - (Tw/2), CY + InnerRadius * 0.4, FUnits, BGRA(100, 100, 100, 200));
end;

procedure TCircularGauge.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, InnerRadius, IndAngle: Single;
  NeedlePts, ShadowPts: array[0..3] of TPointF;
  i: Integer;
begin
  inherited DrawForeground(ABitmap);
  CX := Width / 2;
  CY := Height / 2;
  InnerRadius := (Math.Min(CX, CY) - 4) * 0.85;

  IndAngle := SimMapValue(FValue, FMin, FMax, FMinAngle, FMaxAngle);

  // Hitung Polygon Jarum
  NeedlePts[0] := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.8, IndAngle);        // Ujung atas
  NeedlePts[1] := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.1, IndAngle + 90);   // Kanan dasar
  NeedlePts[2] := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.2, IndAngle + 180);  // Ekor
  NeedlePts[3] := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.1, IndAngle - 90);   // Kiri dasar

  // Bayangan Jarum
  for i := 0 to 3 do
  begin
    ShadowPts[i].X := NeedlePts[i].X + 3;
    ShadowPts[i].Y := NeedlePts[i].Y + 3;
  end;
  ABitmap.FillPolyAntialias(ShadowPts, BGRA(0, 0, 0, 100));

  // Render Jarum (Merah)
  ABitmap.FillPolyAntialias(NeedlePts, BGRA(220, 30, 30, 255));
  ABitmap.DrawPolyLineAntialias(NeedlePts, BGRA(150, 0, 0, 255), 1.0, True);

  // Poros Tengah (Center Cap)
  ABitmap.FillEllipseAntialias(CX, CY, InnerRadius * 0.12, InnerRadius * 0.12, BGRA(20, 20, 20, 255));
  ABitmap.FillEllipseAntialias(CX, CY, InnerRadius * 0.05, InnerRadius * 0.05, BGRA(100, 100, 100, 255));

  // Efek Pantulan Kaca Keseluruhan Gauge
  ABitmap.FillEllipseAntialias(CX - InnerRadius*0.2, CY - InnerRadius*0.4,
                               InnerRadius*0.6, InnerRadius*0.4,
                               BGRA(255, 255, 255, 40));
end;

{ ==============================================================================
  TLinearGauge
  ============================================================================== }

constructor TLinearGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 50;
  Height := 200;
  FMin := 0;
  FMax := 100;
  FValue := 50;
  FOrientation := loVertical;
  FBarColor := clSkyBlue;
end;

procedure TLinearGauge.SetValue(AValue: Extended);
begin
  if FValue = EnsureRange(AValue, FMin, FMax) then Exit;
  FValue := EnsureRange(AValue, FMin, FMax);
  Invalidate;
end;

procedure TLinearGauge.SetMin(AValue: Extended);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  InvalidateBackground;
end;

procedure TLinearGauge.SetMax(AValue: Extended);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  InvalidateBackground;
end;

procedure TLinearGauge.SetOrientation(AValue: TLinearOrientation);
begin
  if FOrientation = AValue then Exit;
  FOrientation := AValue;
  InvalidateBackground;
end;

procedure TLinearGauge.SetBarColor(AValue: TColor);
begin
  if FBarColor = AValue then Exit;
  FBarColor := AValue;
  Invalidate;
end;

procedure TLinearGauge.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect, TrackRect: TRectF;
  GradScanner: IBGRAScanner;
  i: Integer;
  TickPos: Single;
begin
  inherited DrawBackground(ABitmap);

  BaseRect := RectF(2, 2, Width - 2, Height - 2);

  // Bezel Luar
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(230, 230, 230, 255), BGRA(100, 100, 100, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));

  // PERBAIKAN: Pisahkan Fill dan Draw border untuk komponen bentuk
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, BGRA(50, 50, 50, 255), 1);

  // Track Dalam (Slot)
  if FOrientation = loVertical then
    TrackRect := RectF(BaseRect.Left + 8, BaseRect.Top + 8, BaseRect.Right - 20, BaseRect.Bottom - 8)
  else
    TrackRect := RectF(BaseRect.Left + 8, BaseRect.Top + 8, BaseRect.Right - 8, BaseRect.Bottom - 20);

  ABitmap.FillRectAntialias(TrackRect.Left, TrackRect.Top, TrackRect.Right, TrackRect.Bottom, BGRA(30, 30, 30, 255));
  // Inner Shadow Track
  ABitmap.DrawLineAntialias(TrackRect.Left, TrackRect.Top, TrackRect.Right, TrackRect.Top, BGRA(0, 0, 0, 200), 2);
  ABitmap.DrawLineAntialias(TrackRect.Left, TrackRect.Top, TrackRect.Left, TrackRect.Bottom, BGRA(0, 0, 0, 200), 2);

  // Gambar Skala (Ticks)
  for i := 0 to 10 do
  begin
    if FOrientation = loVertical then
    begin
      TickPos := TrackRect.Bottom - (i * ((TrackRect.Bottom - TrackRect.Top) / 10));
      ABitmap.DrawLineAntialias(TrackRect.Right + 2, TickPos, BaseRect.Right - 4, TickPos, BGRA(0, 0, 0, 255), 1.5);
    end
    else
    begin
      TickPos := TrackRect.Left + (i * ((TrackRect.Right - TrackRect.Left) / 10));
      ABitmap.DrawLineAntialias(TickPos, TrackRect.Bottom + 2, TickPos, BaseRect.Bottom - 4, BGRA(0, 0, 0, 255), 1.5);
    end;
  end;
end;

procedure TLinearGauge.DrawForeground(ABitmap: TBGRABitmap);
var
  TrackRect, FillRect: TRectF;
  FillPos: Single;
  C: TBGRAPixel;
begin
  inherited DrawForeground(ABitmap);

  if FOrientation = loVertical then
    TrackRect := RectF(10, 10, Width - 22, Height - 10)
  else
    TrackRect := RectF(10, 10, Width - 10, Height - 22);

  C := ColorToBGRA(ColorToRGB(FBarColor));

  if FOrientation = loVertical then
  begin
    FillPos := SimMapValue(FValue, FMin, FMax, TrackRect.Bottom, TrackRect.Top);
    FillRect := RectF(TrackRect.Left + 1, FillPos, TrackRect.Right - 1, TrackRect.Bottom - 1);
  end
  else
  begin
    FillPos := SimMapValue(FValue, FMin, FMax, TrackRect.Left, TrackRect.Right);
    FillRect := RectF(TrackRect.Left + 1, TrackRect.Top + 1, FillPos, TrackRect.Bottom - 1);
  end;

  // Gambar Bar Level
  ABitmap.FillRectAntialias(FillRect.Left, FillRect.Top, FillRect.Right, FillRect.Bottom, C);

  // Efek Glossy pada Bar
  if FOrientation = loVertical then
    ABitmap.FillRectAntialias(FillRect.Left, FillRect.Top, FillRect.Left + (FillRect.Right-FillRect.Left)*0.3, FillRect.Bottom, BGRA(255,255,255,100))
  else
    ABitmap.FillRectAntialias(FillRect.Left, FillRect.Top, FillRect.Right, FillRect.Top + (FillRect.Bottom-FillRect.Top)*0.3, BGRA(255,255,255,100));
end;

{ ==============================================================================
  TVuMeter
  ============================================================================== }

constructor TVuMeter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 150;
  Height := 100;
  FMin := -20;
  FMax := 3;
  FValue := -20;
end;

procedure TVuMeter.SetValue(AValue: Extended);
begin
  if FValue = EnsureRange(AValue, FMin, FMax) then Exit;
  FValue := EnsureRange(AValue, FMin, FMax);
  Invalidate;
end;

procedure TVuMeter.SetMin(AValue: Extended);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  InvalidateBackground;
end;

procedure TVuMeter.SetMax(AValue: Extended);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  InvalidateBackground;
end;

procedure TVuMeter.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect: TRectF;
  PivotX, PivotY, ArcRadius: Single;
  GradScanner: IBGRAScanner;
  i: Integer;
  TickAngle: Extended;
  P1, P2: TPointF;
begin
  inherited DrawBackground(ABitmap);

  BaseRect := RectF(2, 2, Width - 2, Height - 2);

  // Bezel Hitam Klasik (Pisahkan Fill dan Draw border)
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 5, 5, BGRA(20, 20, 20, 255));
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 5, 5, BGRA(80, 80, 80, 255), 2);

  // Layar Latar Putih/Kuning Gading (Warm White)
  BaseRect := RectF(8, 8, Width - 8, Height - 8);
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(255, 250, 230, 255), BGRA(230, 220, 200, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Left, BaseRect.Bottom));

  // PERBAIKAN: Pisahkan Fill gradien dan Draw border hitam
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 3, 3, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 3, 3, BGRA(0, 0, 0, 255), 1);

  // Pivot point ada di bawah batas komponen
  PivotX := Width / 2;
  PivotY := Height + (Height * 0.2);
  ArcRadius := PivotY - 20;

  // Gambar Skala Arc (Dari Kiri 220° ke Kanan 320°)
  for i := 0 to 20 do
  begin
    TickAngle := 220 + (i * ((320 - 220) / 20));
    P1 := SimPointOnCircle(PointF(PivotX, PivotY), ArcRadius, TickAngle);
    if i mod 4 = 0 then
      P2 := SimPointOnCircle(PointF(PivotX, PivotY), ArcRadius * 0.88, TickAngle)
    else
      P2 := SimPointOnCircle(PointF(PivotX, PivotY), ArcRadius * 0.94, TickAngle);

    // Zona merah di bagian kanan
    if i > 15 then
      ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(200, 0, 0, 255), 2.0)
    else
      ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(0, 0, 0, 255), 1.5);
  end;

  ABitmap.FontHeight := Round(Height * 0.15);
  ABitmap.FontStyle := [fsBold];
  ABitmap.TextOut(PivotX - ABitmap.TextSize('VU').cx/2, Height * 0.6, 'VU', BGRA(50, 50, 50, 255));
end;

procedure TVuMeter.DrawForeground(ABitmap: TBGRABitmap);
var
  PivotX, PivotY, NeedleRadius, IndAngle: Single;
  NeedlePts: array[0..3] of TPointF;
begin
  inherited DrawForeground(ABitmap);

  PivotX := Width / 2;
  PivotY := Height + (Height * 0.2);
  NeedleRadius := PivotY - 15;

  IndAngle := SimMapValue(FValue, FMin, FMax, 220, 320);

  // Jarum Tipis
  NeedlePts[0] := SimPointOnCircle(PointF(PivotX, PivotY), NeedleRadius, IndAngle);
  NeedlePts[1] := SimPointOnCircle(PointF(PivotX, PivotY), NeedleRadius * 0.2, IndAngle + 90);
  NeedlePts[2] := SimPointOnCircle(PointF(PivotX, PivotY), NeedleRadius * 0.1, IndAngle + 180);
  NeedlePts[3] := SimPointOnCircle(PointF(PivotX, PivotY), NeedleRadius * 0.2, IndAngle - 90);

  // Bayangan Jarum
  ABitmap.DrawLineAntialias(NeedlePts[0].X + 2, NeedlePts[0].Y + 2, PivotX + 2, PivotY - (Height*0.2) + 2, BGRA(0, 0, 0, 80), 2.0);

  // Jarum Asli (Hitam)
  ABitmap.DrawLineAntialias(NeedlePts[0].X, NeedlePts[0].Y, PivotX, PivotY - (Height*0.2), BGRA(20, 20, 20, 255), 2.0);

  // Cap Poros Bawah
  ABitmap.FillEllipseAntialias(PivotX, PivotY - (Height*0.2), Width * 0.08, Width * 0.08, BGRA(40, 40, 40, 255));
end;

end.
