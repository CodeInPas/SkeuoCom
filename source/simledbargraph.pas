unit SimLedBarGraph;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  TSimLedBarOrientation = (lboVertical, lboHorizontal);

  { TSimLedBarGraph }
  TSimLedBarGraph = class(TSimGraphicControl)
  private
    FValue: Extended;
    FMin: Extended;
    FMax: Extended;
    FSegmentCount: Integer;
    FOrientation: TSimLedBarOrientation;
    FColorLow: TColor;
    FColorMid: TColor;
    FColorHigh: TColor;

    procedure SetValue(AValue: Extended);
    procedure SetMin(AValue: Extended);
    procedure SetMax(AValue: Extended);
    procedure SetSegmentCount(AValue: Integer);
    procedure SetOrientation(AValue: TSimLedBarOrientation);
    procedure SetColorLow(AValue: TColor);
    procedure SetColorMid(AValue: TColor);
    procedure SetColorHigh(AValue: TColor);

    function GetSegmentColor(Index: Integer): TBGRAPixel;
    function GetSegmentRect(Index: Integer): TRectF;
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Value: Extended read FValue write SetValue;
    property Min: Extended read FMin write SetMin;
    property Max: Extended read FMax write SetMax;
    property SegmentCount: Integer read FSegmentCount write SetSegmentCount default 20;
    property Orientation: TSimLedBarOrientation read FOrientation write SetOrientation default lboVertical;
    property ColorLow: TColor read FColorLow write SetColorLow default clLime;
    property ColorMid: TColor read FColorMid write SetColorMid default clYellow;
    property ColorHigh: TColor read FColorHigh write SetColorHigh default clRed;

    property Align;
    property Anchors;
    property Visible;
    property Width default 30;
    property Height default 200;
  end;

implementation

{ ==============================================================================
  TSimLedBarGraph
  ============================================================================== }

constructor TSimLedBarGraph.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 30;
  Height := 200;
  FMin := 0;
  FMax := 100;
  FValue := 0;
  FSegmentCount := 20;
  FOrientation := lboVertical;
  FColorLow := clLime;
  FColorMid := clYellow;
  FColorHigh := clRed;
end;

procedure TSimLedBarGraph.SetValue(AValue: Extended);
var
  NewVal: Extended;
begin
  NewVal := EnsureRange(AValue, FMin, FMax);
  if FValue = NewVal then Exit;
  FValue := NewVal;
  Invalidate;
end;

procedure TSimLedBarGraph.SetMin(AValue: Extended);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FValue < FMin then SetValue(FMin);
  InvalidateBackground;
end;

procedure TSimLedBarGraph.SetMax(AValue: Extended);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FValue > FMax then SetValue(FMax);
  InvalidateBackground;
end;

procedure TSimLedBarGraph.SetSegmentCount(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if FSegmentCount = AValue then Exit;
  FSegmentCount := AValue;
  InvalidateBackground;
end;

procedure TSimLedBarGraph.SetOrientation(AValue: TSimLedBarOrientation);
var
  Temp: Integer;
begin
  if FOrientation = AValue then Exit;
  FOrientation := AValue;
  if not (csLoading in ComponentState) then
  begin
    Temp := Width;
    Width := Height;
    Height := Temp;
  end;
  InvalidateBackground;
end;

procedure TSimLedBarGraph.SetColorLow(AValue: TColor);
begin
  if FColorLow = AValue then Exit;
  FColorLow := AValue;
  InvalidateBackground;
end;

procedure TSimLedBarGraph.SetColorMid(AValue: TColor);
begin
  if FColorMid = AValue then Exit;
  FColorMid := AValue;
  InvalidateBackground;
end;

procedure TSimLedBarGraph.SetColorHigh(AValue: TColor);
begin
  if FColorHigh = AValue then Exit;
  FColorHigh := AValue;
  InvalidateBackground;
end;

function TSimLedBarGraph.GetSegmentColor(Index: Integer): TBGRAPixel;
var
  Ratio: Single;
begin
  Ratio := Index / FSegmentCount;
  if Ratio <= 0.60 then
    Result := ColorToBGRA(ColorToRGB(FColorLow))
  else if Ratio <= 0.85 then
    Result := ColorToBGRA(ColorToRGB(FColorMid))
  else
    Result := ColorToBGRA(ColorToRGB(FColorHigh));
end;

function TSimLedBarGraph.GetSegmentRect(Index: Integer): TRectF;
var
  Pad, Gap, AvailableSpace, SegSize: Single;
  StartPos: Single;
begin
  Pad := 6;
  Gap := 2;

  if FOrientation = lboVertical then
  begin
    AvailableSpace := Height - (Pad * 2) - (Gap * (FSegmentCount - 1));
    SegSize := AvailableSpace / FSegmentCount;
    // Hitung posisi Y dari bawah ke atas (Index 1 ada di paling bawah)
    StartPos := Height - Pad - (Index * SegSize) - ((Index - 1) * Gap);
    Result := RectF(Pad, StartPos, Width - Pad, StartPos + SegSize);
  end
  else
  begin
    AvailableSpace := Width - (Pad * 2) - (Gap * (FSegmentCount - 1));
    SegSize := AvailableSpace / FSegmentCount;
    // Hitung posisi X dari kiri ke kanan (Index 1 ada di paling kiri)
    StartPos := Pad + ((Index - 1) * SegSize) + ((Index - 1) * Gap);
    Result := RectF(StartPos, Pad, StartPos + SegSize, Height - Pad);
  end;
end;

procedure TSimLedBarGraph.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect: TRectF;
  GradScanner: IBGRAScanner;
  i: Integer;
  SegRect: TRectF;
  SegColor: TBGRAPixel;
begin
  inherited DrawBackground(ABitmap);

  BaseRect := RectF(2, 2, Width - 2, Height - 2);

  // 1. Gambar Bezel Luar (Panel Gelap)
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(60, 60, 60, 255), BGRA(20, 20, 20, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, BGRA(0, 0, 0, 255), 1.5);

  // 2. Inner Shadow Bezel
  ABitmap.DrawLineAntialias(BaseRect.Left + 2, BaseRect.Top + 2, BaseRect.Right - 2, BaseRect.Top + 2, BGRA(0, 0, 0, 180), 2);
  ABitmap.DrawLineAntialias(BaseRect.Left + 2, BaseRect.Top + 2, BaseRect.Left + 2, BaseRect.Bottom - 2, BGRA(0, 0, 0, 180), 2);

  // 3. Gambar Segmen LED yang MATI (Unlit)
  for i := 1 to FSegmentCount do
  begin
    SegRect := GetSegmentRect(i);
    SegColor := GetSegmentColor(i);
    // Gelapkan warna untuk state mati (opacity 40, kecerahan dikurangi)
    SegColor.red := SegColor.red div 4;
    SegColor.green := SegColor.green div 4;
    SegColor.blue := SegColor.blue div 4;
    SegColor.alpha := 255;

    ABitmap.FillRectAntialias(SegRect.Left, SegRect.Top, SegRect.Right, SegRect.Bottom, SegColor);
    // Inner bevel LED mati
    ABitmap.DrawLineAntialias(SegRect.Left, SegRect.Top, SegRect.Right, SegRect.Top, BGRA(0, 0, 0, 150), 1);
  end;
end;

procedure TSimLedBarGraph.DrawForeground(ABitmap: TBGRABitmap);
var
  i, ActiveCount: Integer;
  SegRect, GlowRect: TRectF;
  SegColor: TBGRAPixel;
begin
  inherited DrawForeground(ABitmap);

  if FMax <= FMin then Exit;

  // Hitung jumlah segmen yang menyala
  ActiveCount := Round(((FValue - FMin) / (FMax - FMin)) * FSegmentCount);
  ActiveCount := EnsureRange(ActiveCount, 0, FSegmentCount);

  // Gambar Segmen LED yang MENYALA (Lit)
  for i := 1 to ActiveCount do
  begin
    SegRect := GetSegmentRect(i);
    SegColor := GetSegmentColor(i);

    // Inti LED yang sangat terang
    ABitmap.FillRectAntialias(SegRect.Left, SegRect.Top, SegRect.Right, SegRect.Bottom, SegColor);

    // Highlight putih di tengah LED
    if FOrientation = lboVertical then
      ABitmap.FillRectAntialias(SegRect.Left + 2, SegRect.Top + 1, SegRect.Right - 2, SegRect.Top + ((SegRect.Bottom-SegRect.Top)/2), BGRA(255, 255, 255, 100))
    else
      ABitmap.FillRectAntialias(SegRect.Left + 1, SegRect.Top + 2, SegRect.Left + ((SegRect.Right-SegRect.Left)/2), SegRect.Bottom - 2, BGRA(255, 255, 255, 100));

    // Efek Pendaran / Glow (Lebih besar dari rect asli)
    GlowRect := RectF(SegRect.Left - 2, SegRect.Top - 2, SegRect.Right + 2, SegRect.Bottom + 2);
    SegColor.alpha := 80; // Transparan untuk glow
    ABitmap.FillRoundRectAntialias(GlowRect.Left, GlowRect.Top, GlowRect.Right, GlowRect.Bottom, 2, 2, SegColor);
  end;
end;

end.
