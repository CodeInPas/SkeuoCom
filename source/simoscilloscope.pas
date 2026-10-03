unit SimOscilloscope;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  TSimSignalType = (stSine, stSquare, stTriangle);

  { TSimOscilloscope }
  TSimOscilloscope = class(TSimGraphicControl)
  private
    FGridColor: TColor;
    FTraceColor: TColor;
    FSignalType: TSimSignalType;
    FFrequency: Single;
    FAmplitude: Single;
    FPhase: Single;
    FShowGrid: Boolean;

    procedure SetGridColor(AValue: TColor);
    procedure SetTraceColor(AValue: TColor);
    procedure SetSignalType(AValue: TSimSignalType);
    procedure SetFrequency(AValue: Single);
    procedure SetAmplitude(AValue: Single);
    procedure SetPhase(AValue: Single);
    procedure SetShowGrid(AValue: Boolean);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property GridColor: TColor read FGridColor write SetGridColor default $00204000;
    property TraceColor: TColor read FTraceColor write SetTraceColor default clLime;
    property SignalType: TSimSignalType read FSignalType write SetSignalType default stSine;
    property Frequency: Single read FFrequency write SetFrequency;
    property Amplitude: Single read FAmplitude write SetAmplitude;
    property Phase: Single read FPhase write SetPhase;
    property ShowGrid: Boolean read FShowGrid write SetShowGrid default True;

    property Align;
    property Anchors;
    property Visible;
    property Width default 250;
    property Height default 150;
  end;

implementation

{ ==============================================================================
  TSimOscilloscope
  ============================================================================== }

constructor TSimOscilloscope.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 250;
  Height := 150;
  FGridColor := $00204000; // Hijau gelap
  FTraceColor := clLime;
  FSignalType := stSine;
  FFrequency := 2.0;       // 2 gelombang penuh di layar
  FAmplitude := 0.8;       // 80% dari tinggi maksimal layar
  FPhase := 0.0;
  FShowGrid := True;
end;

procedure TSimOscilloscope.SetGridColor(AValue: TColor);
begin
  if FGridColor = AValue then Exit;
  FGridColor := AValue;
  InvalidateBackground;
end;

procedure TSimOscilloscope.SetTraceColor(AValue: TColor);
begin
  if FTraceColor = AValue then Exit;
  FTraceColor := AValue;
  Invalidate;
end;

procedure TSimOscilloscope.SetSignalType(AValue: TSimSignalType);
begin
  if FSignalType = AValue then Exit;
  FSignalType := AValue;
  Invalidate;
end;

procedure TSimOscilloscope.SetFrequency(AValue: Single);
begin
  if FFrequency = AValue then Exit;
  FFrequency := AValue;
  Invalidate;
end;

procedure TSimOscilloscope.SetAmplitude(AValue: Single);
begin
  if FAmplitude = EnsureRange(AValue, 0.0, 1.0) then Exit;
  FAmplitude := EnsureRange(AValue, 0.0, 1.0);
  Invalidate;
end;

procedure TSimOscilloscope.SetPhase(AValue: Single);
begin
  if FPhase = AValue then Exit;
  FPhase := AValue;
  Invalidate;
end;

procedure TSimOscilloscope.SetShowGrid(AValue: Boolean);
begin
  if FShowGrid = AValue then Exit;
  FShowGrid := AValue;
  InvalidateBackground;
end;

procedure TSimOscilloscope.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect, ScreenRect: TRectF;
  GradScanner: IBGRAScanner;
  x, y: Single;
  GridC: TBGRAPixel;
  DivX, DivY: Single;
begin
  inherited DrawBackground(ABitmap);

  BaseRect := RectF(2, 2, Width - 2, Height - 2);

  // 1. Casing / Bezel Luar
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(90, 90, 90, 255), BGRA(30, 30, 30, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 5, 5, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 5, 5, BGRA(0, 0, 0, 255), 1.5);

  // 2. Layar CRT (Gelap)
  ScreenRect := RectF(10, 10, Width - 10, Height - 10);
  ABitmap.FillRoundRectAntialias(ScreenRect.Left, ScreenRect.Top, ScreenRect.Right, ScreenRect.Bottom, 3, 3, BGRA(5, 15, 5, 255));

  // Efek Vignette pada pinggiran layar (Bayangan dalam)
  ABitmap.RoundRectAntialias(ScreenRect.Left, ScreenRect.Top, ScreenRect.Right, ScreenRect.Bottom, 3, 3, BGRA(0, 0, 0, 200), 4.0);

  // 3. Grid Graticule (Tanda Divisi)
  if FShowGrid then
  begin
    GridC := ColorToBGRA(ColorToRGB(FGridColor));
    DivX := (ScreenRect.Right - ScreenRect.Left) / 10; // 10 Divisi Horizontal
    DivY := (ScreenRect.Bottom - ScreenRect.Top) / 8;  // 8 Divisi Vertikal

    // Garis Vertikal
    x := ScreenRect.Left + DivX;
    while x < ScreenRect.Right - 1 do
    begin
      // Garis tengah lebih tebal
      if Abs(x - (ScreenRect.Left + (ScreenRect.Right - ScreenRect.Left)/2)) < 1 then
        ABitmap.DrawLineAntialias(x, ScreenRect.Top, x, ScreenRect.Bottom, GridC, 1.5)
      else
        ABitmap.DrawLineAntialias(x, ScreenRect.Top, x, ScreenRect.Bottom, GridC, 0.5);
      x := x + DivX;
    end;

    // Garis Horizontal
    y := ScreenRect.Top + DivY;
    while y < ScreenRect.Bottom - 1 do
    begin
      // Garis tengah lebih tebal
      if Abs(y - (ScreenRect.Top + (ScreenRect.Bottom - ScreenRect.Top)/2)) < 1 then
        ABitmap.DrawLineAntialias(ScreenRect.Left, y, ScreenRect.Right, y, GridC, 1.5)
      else
        ABitmap.DrawLineAntialias(ScreenRect.Left, y, ScreenRect.Right, y, GridC, 0.5);
      y := y + DivY;
    end;
  end;
end;

procedure TSimOscilloscope.DrawForeground(ABitmap: TBGRABitmap);
var
  ScreenRect: TRectF;
  Pts: array of TPointF;
  i, PtCount: Integer;
  t, val, CenterY, MaxAmpY: Single;
  TraceC, GlowC: TBGRAPixel;
begin
  inherited DrawForeground(ABitmap);

  ScreenRect := RectF(10, 10, Width - 10, Height - 10);
  CenterY := ScreenRect.Top + (ScreenRect.Bottom - ScreenRect.Top) / 2;
  MaxAmpY := (ScreenRect.Bottom - ScreenRect.Top) / 2 * 0.95; // 95% margin layar

  PtCount := Round(ScreenRect.Right - ScreenRect.Left);
  if PtCount <= 0 then Exit;

  SetLength(Pts, PtCount);

  // Kalkulasi Titik Gelombang
  for i := 0 to PtCount - 1 do
  begin
    t := (i / PtCount) * 2 * Pi * FFrequency + FPhase;

    case FSignalType of
      stSine:
        val := Sin(t);
      stSquare:
        if Sin(t) >= 0 then val := 1.0 else val := -1.0;
      stTriangle:
        val := (2 / Pi) * ArcSin(Sin(t));
    end;

    Pts[i].X := ScreenRect.Left + i;
    Pts[i].Y := CenterY - (val * FAmplitude * MaxAmpY);
  end;

  TraceC := ColorToBGRA(ColorToRGB(FTraceColor));
  GlowC := TraceC;
  GlowC.alpha := 60; // Transparansi pendaran layar fosfor

  // Render Pendaran (Glow)
  ABitmap.DrawPolyLineAntialias(Pts, GlowC, 5.0, False);
  ABitmap.DrawPolyLineAntialias(Pts, GlowC, 3.0, False);

  // Render Inti Garis
  ABitmap.DrawPolyLineAntialias(Pts, TraceC, 1.5, False);

  // Kaca CRT Pantulan (Gloss Overlay)
  ABitmap.FillEllipseAntialias(Width / 2, Height / 2 - (Height * 0.4),
                               Width * 0.4, Height * 0.2,
                               BGRA(255, 255, 255, 20));
end;

end.
