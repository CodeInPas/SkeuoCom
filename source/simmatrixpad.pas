unit SimMatrixPad;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  TSimPadClickEvent = procedure(Sender: TObject; Col, Row: Integer; State: Boolean) of object;

  { TSimMatrixPad }
  TSimMatrixPad = class(TSimGraphicControl)
  private
    FRows: Integer;
    FCols: Integer;
    FSpacing: Single;
    FPadPadding: Single;
    FPadColor: TColor;
    FActiveColor: TColor;
    FPadStates: array of Boolean;
    FOnPadClick: TSimPadClickEvent;

    procedure SetRows(AValue: Integer);
    procedure SetCols(AValue: Integer);
    procedure SetSpacing(AValue: Single);
    procedure SetPadPadding(AValue: Single);
    procedure SetPadColor(AValue: TColor);
    procedure SetActiveColor(AValue: TColor);
    procedure RebuildPadArray;

    function GetPadRect(Col, Row: Integer): TRectF;
  protected
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;

    function GetPadState(Col, Row: Integer): Boolean;
    procedure SetPadState(Col, Row: Integer; AState: Boolean);
    procedure ClearAll;
  published
    property Rows: Integer read FRows write SetRows default 4;
    property Cols: Integer read FCols write SetCols default 4;
    property Spacing: Single read FSpacing write SetSpacing;
    property PadPadding: Single read FPadPadding write SetPadPadding;
    property PadColor: TColor read FPadColor write SetPadColor default $00505050;
    property ActiveColor: TColor read FActiveColor write SetActiveColor default clAqua;

    property OnPadClick: TSimPadClickEvent read FOnPadClick write FOnPadClick;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 200;
    property Height default 200;
  end;

implementation

{ ==============================================================================
  TSimMatrixPad
  ============================================================================== }

constructor TSimMatrixPad.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 200;
  FRows := 4;
  FCols := 4;
  FSpacing := 6.0;
  FPadPadding := 10.0;
  FPadColor := $00505050; // Abu-abu gelap
  FActiveColor := clAqua;
  RebuildPadArray;
end;

procedure TSimMatrixPad.RebuildPadArray;
var
  i, TotalPads: Integer;
begin
  TotalPads := FRows * FCols;
  SetLength(FPadStates, TotalPads);
  for i := 0 to TotalPads - 1 do
    FPadStates[i] := False;
end;

procedure TSimMatrixPad.SetRows(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if FRows = AValue then Exit;
  FRows := AValue;
  RebuildPadArray;
  InvalidateBackground;
end;

procedure TSimMatrixPad.SetCols(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if FCols = AValue then Exit;
  FCols := AValue;
  RebuildPadArray;
  InvalidateBackground;
end;

procedure TSimMatrixPad.SetSpacing(AValue: Single);
begin
  if FSpacing = AValue then Exit;
  FSpacing := AValue;
  InvalidateBackground;
end;

procedure TSimMatrixPad.SetPadPadding(AValue: Single);
begin
  if FPadPadding = AValue then Exit;
  FPadPadding := AValue;
  InvalidateBackground;
end;

procedure TSimMatrixPad.SetPadColor(AValue: TColor);
begin
  if FPadColor = AValue then Exit;
  FPadColor := AValue;
  Invalidate;
end;

procedure TSimMatrixPad.SetActiveColor(AValue: TColor);
begin
  if FActiveColor = AValue then Exit;
  FActiveColor := AValue;
  Invalidate;
end;

function TSimMatrixPad.GetPadState(Col, Row: Integer): Boolean;
var
  Idx: Integer;
begin
  if (Col < 0) or (Col >= FCols) or (Row < 0) or (Row >= FRows) then Exit(False);
  Idx := (Row * FCols) + Col;
  Result := FPadStates[Idx];
end;

procedure TSimMatrixPad.SetPadState(Col, Row: Integer; AState: Boolean);
var
  Idx: Integer;
begin
  if (Col < 0) or (Col >= FCols) or (Row < 0) or (Row >= FRows) then Exit;
  Idx := (Row * FCols) + Col;
  if FPadStates[Idx] = AState then Exit;
  FPadStates[Idx] := AState;
  Invalidate;
end;

procedure TSimMatrixPad.ClearAll;
var
  i: Integer;
begin
  for i := 0 to Length(FPadStates) - 1 do
    FPadStates[i] := False;
  Invalidate;
end;

function TSimMatrixPad.GetPadRect(Col, Row: Integer): TRectF;
var
  AvailableW, AvailableH, PadW, PadH: Single;
  Px, Py: Single;
begin
  AvailableW := Width - (FPadPadding * 2) - (FSpacing * (FCols - 1));
  AvailableH := Height - (FPadPadding * 2) - (FSpacing * (FRows - 1));

  PadW := AvailableW / FCols;
  PadH := AvailableH / FRows;

  Px := FPadPadding + (Col * PadW) + (Col * FSpacing);
  Py := FPadPadding + (Row * PadH) + (Row * FSpacing);

  Result := RectF(Px, Py, Px + PadW, Py + PadH);
end;

procedure TSimMatrixPad.Resize;
begin
  inherited Resize;
  InvalidateBackground;
end;

procedure TSimMatrixPad.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col, Row: Integer;
  PRect: TRectF;
  Idx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if (Button = mbLeft) and Enabled then
  begin
    for Row := 0 to FRows - 1 do
    begin
      for Col := 0 to FCols - 1 do
      begin
        PRect := GetPadRect(Col, Row);
        if (X >= PRect.Left) and (X <= PRect.Right) and (Y >= PRect.Top) and (Y <= PRect.Bottom) then
        begin
          Idx := (Row * FCols) + Col;
          FPadStates[Idx] := not FPadStates[Idx]; // Toggle state

          if Assigned(FOnPadClick) then
            FOnPadClick(Self, Col, Row, FPadStates[Idx]);

          Invalidate;
          Exit;
        end;
      end;
    end;
  end;
end;

procedure TSimMatrixPad.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect: TRectF;
  GradScanner: IBGRAScanner;
begin
  inherited DrawBackground(ABitmap);

  BaseRect := RectF(2, 2, Width - 2, Height - 2);

  // Panel Chassis Matrix (Besi Gelap)
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(60, 60, 60, 255), BGRA(30, 30, 30, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));

  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 6, 6, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 6, 6, BGRA(0, 0, 0, 255), 2.0);

  // Inner Shadow Chassis
  ABitmap.DrawLineAntialias(BaseRect.Left + 2, BaseRect.Top + 2, BaseRect.Right - 2, BaseRect.Top + 2, BGRA(0, 0, 0, 180), 2.0);
  ABitmap.DrawLineAntialias(BaseRect.Left + 2, BaseRect.Top + 2, BaseRect.Left + 2, BaseRect.Bottom - 2, BGRA(0, 0, 0, 180), 2.0);
end;

procedure TSimMatrixPad.DrawForeground(ABitmap: TBGRABitmap);
var
  Col, Row, Idx: Integer;
  PRect, InnerRect: TRectF;
  GradScanner: IBGRAScanner;
  BaseC, ActiveC, DrawC: TBGRAPixel;
  R, G, B: Byte;
begin
  inherited DrawForeground(ABitmap);

  BaseC := ColorToBGRA(ColorToRGB(FPadColor));
  ActiveC := ColorToBGRA(ColorToRGB(FActiveColor));

  for Row := 0 to FRows - 1 do
  begin
    for Col := 0 to FCols - 1 do
    begin
      Idx := (Row * FCols) + Col;
      PRect := GetPadRect(Col, Row);

      // Shadow lubang pad
      ABitmap.FillRoundRectAntialias(PRect.Left, PRect.Top, PRect.Right, PRect.Bottom, 4, 4, BGRA(15, 15, 15, 255));

      // Pad Body
      InnerRect := RectF(PRect.Left + 2, PRect.Top + 2, PRect.Right - 2, PRect.Bottom - 2);

      if FPadStates[Idx] then
      begin
        // State MENYALA (ON)
        R := ActiveC.red;
        G := ActiveC.green;
        B := ActiveC.blue;

        GradScanner := TBGRAGradientScanner.Create(
          BGRA(Min(255, R+80), Min(255, G+80), Min(255, B+80), 255),
          BGRA(Max(0, R-30), Max(0, G-30), Max(0, B-30), 255),
          gtLinear, PointF(InnerRect.Left, InnerRect.Top), PointF(InnerRect.Right, InnerRect.Bottom));

        ABitmap.FillRoundRectAntialias(InnerRect.Left, InnerRect.Top, InnerRect.Right, InnerRect.Bottom, 3, 3, GradScanner);

        // Pendaran (Glow)
        ActiveC.alpha := 60;
        ABitmap.FillRoundRectAntialias(InnerRect.Left - 2, InnerRect.Top - 2, InnerRect.Right + 2, InnerRect.Bottom + 2, 4, 4, ActiveC);

        // Highlight putih (Kesan silikon menyala)
        ABitmap.FillRoundRectAntialias(InnerRect.Left + 4, InnerRect.Top + 4, InnerRect.Right - 4, InnerRect.Top + ((InnerRect.Bottom-InnerRect.Top)/2), 2, 2, BGRA(255, 255, 255, 120));
      end
      else
      begin
        // State MATI (OFF)
        R := BaseC.red;
        G := BaseC.green;
        B := BaseC.blue;

        GradScanner := TBGRAGradientScanner.Create(
          BGRA(Min(255, R+30), Min(255, G+30), Min(255, B+30), 255),
          BGRA(Max(0, R-30), Max(0, G-30), Max(0, B-30), 255),
          gtLinear, PointF(InnerRect.Left, InnerRect.Top), PointF(InnerRect.Right, InnerRect.Bottom));

        ABitmap.FillRoundRectAntialias(InnerRect.Left, InnerRect.Top, InnerRect.Right, InnerRect.Bottom, 3, 3, GradScanner);

        // Highlight redup
        ABitmap.DrawLineAntialias(InnerRect.Left + 2, InnerRect.Top + 1, InnerRect.Right - 2, InnerRect.Top + 1, BGRA(255, 255, 255, 40), 1.0);
      end;

      // Border Pad
      ABitmap.RoundRectAntialias(InnerRect.Left, InnerRect.Top, InnerRect.Right, InnerRect.Bottom, 3, 3, BGRA(0, 0, 0, 200), 1.0);
    end;
  end;
end;

end.
