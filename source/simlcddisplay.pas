unit SimLcdDisplay;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TSimLcdDisplay }
  TSimLcdDisplay = class(TSimGraphicControl)
  private
    FLines: TStrings;
    FLcdColor: TColor;
    FTextColor: TColor;
    FShowPixelGrid: Boolean;
    FBorderWidth: Integer;

    procedure SetLines(AValue: TStrings);
    procedure SetLcdColor(AValue: TColor);
    procedure SetTextColor(AValue: TColor);
    procedure SetShowPixelGrid(AValue: Boolean);
    procedure SetBorderWidth(AValue: Integer);
    procedure LinesChanged(Sender: TObject);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Lines: TStrings read FLines write SetLines;
    property LcdColor: TColor read FLcdColor write SetLcdColor default $002AB958; // Classic Yellow-Green
    property TextColor: TColor read FTextColor write SetTextColor default $00123512; // Dark Green/Black
    property ShowPixelGrid: Boolean read FShowPixelGrid write SetShowPixelGrid default True;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 8;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Font;
    property Width default 200;
    property Height default 60;
  end;

implementation

{ ==============================================================================
  TSimLcdDisplay
  ============================================================================== }

constructor TSimLcdDisplay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 60;
  FBorderWidth := 8;
  FLcdColor := $002AB958;
  FTextColor := $00123512;
  FShowPixelGrid := True;

  FLines := TStringList.Create;
  TStringList(FLines).OnChange := @LinesChanged;
  FLines.Add('SYSTEM READY');

  Font.Name := 'Courier New';
  Font.Style := [fsBold];
  Font.Size := 12;
end;

destructor TSimLcdDisplay.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TSimLcdDisplay.SetLines(AValue: TStrings);
begin
  FLines.Assign(AValue);
end;

procedure TSimLcdDisplay.LinesChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TSimLcdDisplay.SetLcdColor(AValue: TColor);
begin
  if FLcdColor = AValue then Exit;
  FLcdColor := AValue;
  InvalidateBackground;
end;

procedure TSimLcdDisplay.SetTextColor(AValue: TColor);
begin
  if FTextColor = AValue then Exit;
  FTextColor := AValue;
  Invalidate;
end;

procedure TSimLcdDisplay.SetShowPixelGrid(AValue: Boolean);
begin
  if FShowPixelGrid = AValue then Exit;
  FShowPixelGrid := AValue;
  InvalidateBackground;
end;

procedure TSimLcdDisplay.SetBorderWidth(AValue: Integer);
begin
  if FBorderWidth = AValue then Exit;
  FBorderWidth := Max(2, AValue);
  InvalidateBackground;
end;

procedure TSimLcdDisplay.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect, ScreenRect: TRectF;
  GradScanner: IBGRAScanner;
  LcdC: TBGRAPixel;
  x, y: Single;
begin
  inherited DrawBackground(ABitmap);

  BaseRect := RectF(2, 2, Width - 2, Height - 2);

  // 1. Bezel Panel (Logam Gelap / Plastik)
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(70, 70, 70, 255), BGRA(20, 20, 20, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, BGRA(0, 0, 0, 255), 1.5);

  // 2. LCD Screen Glass Background
  ScreenRect := RectF(FBorderWidth, FBorderWidth, Width - FBorderWidth, Height - FBorderWidth);
  LcdC := ColorToBGRA(ColorToRGB(FLcdColor));

  ABitmap.FillRoundRectAntialias(ScreenRect.Left, ScreenRect.Top, ScreenRect.Right, ScreenRect.Bottom, 2, 2, LcdC);

  // 3. Inner Shadow (Tepi Kaca Gelap)
  ABitmap.DrawLineAntialias(ScreenRect.Left, ScreenRect.Top, ScreenRect.Right, ScreenRect.Top, BGRA(0, 0, 0, 150), 3.0);
  ABitmap.DrawLineAntialias(ScreenRect.Left, ScreenRect.Top, ScreenRect.Left, ScreenRect.Bottom, BGRA(0, 0, 0, 150), 3.0);
  ABitmap.DrawLineAntialias(ScreenRect.Right, ScreenRect.Bottom, ScreenRect.Right, ScreenRect.Top, BGRA(255, 255, 255, 100), 1.0);

  // 4. Grid Pixel LCD Overlay (Opsional)
  if FShowPixelGrid then
  begin
    x := ScreenRect.Left + 2;
    while x < ScreenRect.Right do
    begin
      ABitmap.DrawLineAntialias(x, ScreenRect.Top, x, ScreenRect.Bottom, BGRA(0, 0, 0, 15), 1.0);
      x := x + 3; // Jarak antar pixel horizontal
    end;

    y := ScreenRect.Top + 2;
    while y < ScreenRect.Bottom do
    begin
      ABitmap.DrawLineAntialias(ScreenRect.Left, y, ScreenRect.Right, y, BGRA(0, 0, 0, 15), 1.0);
      y := y + 3; // Jarak antar pixel vertikal
    end;
  end;
end;

procedure TSimLcdDisplay.DrawForeground(ABitmap: TBGRABitmap);
var
  ScreenRect: TRectF;
  TxtC, ShadowC: TBGRAPixel;
  i: Integer;
  LineText: String;
  TextX, TextY, LineH: Single;
begin
  inherited DrawForeground(ABitmap);

  ScreenRect := RectF(FBorderWidth, FBorderWidth, Width - FBorderWidth, Height - FBorderWidth);

  ABitmap.FontName := Font.Name;
  if Abs(Font.Height) > 0 then ABitmap.FontHeight := Abs(Font.Height) else ABitmap.FontHeight := 14;
  ABitmap.FontStyle := Font.Style;
  ABitmap.FontAntialias := False; // True LCD fonts biasanya tidak antialias (tajam)

  TxtC := ColorToBGRA(ColorToRGB(FTextColor));
  ShadowC := TxtC;
  ShadowC.alpha := 40; // Efek ghosting LCD (Karakter pudar di belakang)

  LineH := ABitmap.FontHeight + 2;

  for i := 0 to FLines.Count - 1 do
  begin
    LineText := FLines[i];
    if LineText = '' then Continue;

    // Teks dimulai dari kiri atas dengan sedikit padding
    TextX := ScreenRect.Left + 5;
    TextY := ScreenRect.Top + 5 + (i * LineH);

    // Cegah render di luar layar
    if TextY + LineH > ScreenRect.Bottom then Break;

    // Render Shadow / Ghosting (sedikit bergeser)
    ABitmap.TextOut(TextX + 1, TextY + 1, LineText, ShadowC);

    // Render Teks Utama
    ABitmap.TextOut(TextX, TextY, LineText, TxtC);
  end;

  // Efek Pantulan Cahaya (Glossy Screen)
  ABitmap.FillRoundRectAntialias(ScreenRect.Left, ScreenRect.Top,
                                 ScreenRect.Right, ScreenRect.Top + ((ScreenRect.Bottom - ScreenRect.Top) * 0.3),
                                 2, 2, BGRA(255, 255, 255, 25));
end;

end.
