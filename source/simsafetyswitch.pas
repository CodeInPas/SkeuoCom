unit SimSafetySwitch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TSimSafetySwitch }
  TSimSafetySwitch = class(TSimCustomControl)
  private
    FIsOn: Boolean;
    FCoverOpen: Boolean;
    FCoverColor: TColor;
    FOnChange: TNotifyEvent;
    FOnCoverChange: TNotifyEvent;

    procedure SetIsOn(AValue: Boolean);
    procedure SetCoverOpen(AValue: Boolean);
    procedure SetCoverColor(AValue: TColor);
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property IsOn: Boolean read FIsOn write SetIsOn default False;
    property CoverOpen: Boolean read FCoverOpen write SetCoverOpen default False;
    property CoverColor: TColor read FCoverColor write SetCoverColor default clRed;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnCoverChange: TNotifyEvent read FOnCoverChange write FOnCoverChange;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 60;
    property Height default 100;
  end;

implementation

{ ==============================================================================
  TSimSafetySwitch
  ============================================================================== }

constructor TSimSafetySwitch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 60;
  Height := 100;
  FIsOn := False;
  FCoverOpen := False;
  FCoverColor := clRed;
end;

procedure TSimSafetySwitch.SetIsOn(AValue: Boolean);
begin
  if FIsOn = AValue then Exit;
  // Jika cover tertutup, switch tidak bisa dihidupkan (hanya bisa OFF)
  if (not FCoverOpen) and AValue then Exit;

  FIsOn := AValue;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimSafetySwitch.SetCoverOpen(AValue: Boolean);
begin
  if FCoverOpen = AValue then Exit;
  FCoverOpen := AValue;

  // Fitur Keamanan: Menutup cover otomatis mematikan switch
  if (not FCoverOpen) and FIsOn then
    SetIsOn(False);

  Invalidate;
  if Assigned(FOnCoverChange) then FOnCoverChange(Self);
end;

procedure TSimSafetySwitch.SetCoverColor(AValue: TColor);
begin
  if FCoverColor = AValue then Exit;
  FCoverColor := AValue;
  Invalidate;
end;

procedure TSimSafetySwitch.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  HitTopHalf: Boolean;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if not Enabled then Exit;

  HitTopHalf := (Y < Height / 2);

  if Button = mbLeft then
  begin
    if not FCoverOpen then
    begin
      // Jika tertutup, klik di mana saja membuka cover
      SetCoverOpen(True);
    end
    else
    begin
      // Jika terbuka, area atas (cover) untuk menutup, area bawah (switch) untuk toggle
      if HitTopHalf then
        SetCoverOpen(False)
      else
        SetIsOn(not FIsOn);
    end;
  end;
end;

procedure TSimSafetySwitch.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY: Single;
  BaseRect: TRectF;
  GradScanner: IBGRAScanner;
begin
  inherited DrawBackground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;

  // 1. Plat Besi Dudukan Switch (Bagian bawah)
  BaseRect := RectF(CX - 15, CY - 10, CX + 15, CY + 35);

  GradScanner := TBGRAGradientScanner.Create(
    BGRA(180, 180, 180, 255), BGRA(80, 80, 80, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));

  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 3, 3, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 3, 3, BGRA(40, 40, 40, 255), 1.5);

  // Mur / Baut dudukan
  ABitmap.FillEllipseAntialias(CX, CY - 5, 2, 2, BGRA(40, 40, 40, 255));
  ABitmap.FillEllipseAntialias(CX, CY + 30, 2, 2, BGRA(40, 40, 40, 255));

  // Lubang Engsel (Hinge Mount) di tengah/atas
  ABitmap.FillRoundRectAntialias(CX - 20, CY - 15, CX + 20, CY - 5, 2, 2, BGRA(60, 60, 60, 255));
  ABitmap.RoundRectAntialias(CX - 20, CY - 15, CX + 20, CY - 5, 2, 2, BGRA(0, 0, 0, 255), 1.0);
end;

procedure TSimSafetySwitch.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY: Single;
  C: TBGRAPixel;
  R, G, B: Byte;
  GradScanner: IBGRAScanner;
  LeverPts: array[0..3] of TPointF;
  CoverPts: array[0..3] of TPointF;
begin
  inherited DrawForeground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;

  C := ColorToBGRA(ColorToRGB(FCoverColor));
  R := C.red; G := C.green; B := C.blue;

  // =====================================================================
  // RENDER SWITCH BATANG (Hanya digambar penuh jika cover terbuka)
  // =====================================================================
  if FCoverOpen then
  begin
    // Bayangan lubang switch
    ABitmap.FillEllipseAntialias(CX, CY + 12, 10, 10, BGRA(20, 20, 20, 255));

    // Posisi Switch Lever
    if FIsOn then
    begin
      // Switch arah ATAS (ON)
      LeverPts[0] := PointF(CX - 4, CY + 14);
      LeverPts[1] := PointF(CX + 4, CY + 14);
      LeverPts[2] := PointF(CX + 2, CY - 5);
      LeverPts[3] := PointF(CX - 2, CY - 5);
    end
    else
    begin
      // Switch arah BAWAH (OFF)
      LeverPts[0] := PointF(CX - 4, CY + 10);
      LeverPts[1] := PointF(CX + 4, CY + 10);
      LeverPts[2] := PointF(CX + 2, CY + 30);
      LeverPts[3] := PointF(CX - 2, CY + 30);
    end;

    GradScanner := TBGRAGradientScanner.Create(
      BGRA(230, 230, 230, 255), BGRA(100, 100, 100, 255),
      gtLinear, LeverPts[0], LeverPts[2]);

    ABitmap.FillPolyAntialias(LeverPts, GradScanner);
    ABitmap.DrawPolyLineAntialias(LeverPts, BGRA(50, 50, 50, 255), 1.0, True);
  end;

  // =====================================================================
  // RENDER SAFETY COVER
  // =====================================================================
  if FCoverOpen then
  begin
    // Cover Terbuka (Mengarah ke atas)
    CoverPts[0] := PointF(CX - 20, CY - 10); // Engsel Kiri
    CoverPts[1] := PointF(CX + 20, CY - 10); // Engsel Kanan
    CoverPts[2] := PointF(CX + 15, 5);       // Ujung Atas Kanan
    CoverPts[3] := PointF(CX - 15, 5);       // Ujung Atas Kiri

    // Bagian Dalam Cover (Lebih gelap)
    GradScanner := TBGRAGradientScanner.Create(
      BGRA(Max(0, R-80), Max(0, G-80), Max(0, B-80), 255),
      BGRA(Max(0, R-120), Max(0, G-120), Max(0, B-120), 255),
      gtLinear, PointF(CX, CY - 10), PointF(CX, 5));

    ABitmap.FillPolyAntialias(CoverPts, GradScanner);
    ABitmap.DrawPolyLineAntialias(CoverPts, BGRA(0, 0, 0, 255), 1.5, True);

    // Dinding Samping Cover (Kesan 3D bagian dalam)
    ABitmap.DrawLineAntialias(CX - 20, CY - 10, CX - 15, 5, BGRA(255, 255, 255, 100), 2.0);
    ABitmap.DrawLineAntialias(CX + 20, CY - 10, CX + 15, 5, BGRA(0, 0, 0, 100), 2.0);
  end
  else
  begin
    // Cover Tertutup (Mengarah ke bawah, menutupi switch)
    CoverPts[0] := PointF(CX - 20, CY - 10); // Engsel Kiri
    CoverPts[1] := PointF(CX + 20, CY - 10); // Engsel Kanan
    CoverPts[2] := PointF(CX + 18, CY + 45); // Ujung Bawah Kanan
    CoverPts[3] := PointF(CX - 18, CY + 45); // Ujung Bawah Kiri

    // Shadow jatuh dari cover ke plat
    ABitmap.FillPolyAntialias(
      [PointF(CX - 16, CY + 5), PointF(CX + 24, CY + 5),
       PointF(CX + 22, CY + 48), PointF(CX - 14, CY + 48)],
      BGRA(0, 0, 0, 120));

    // Wajah Luar Cover (Terang)
    GradScanner := TBGRAGradientScanner.Create(
      BGRA(Min(255, R+40), Min(255, G+40), Min(255, B+40), 255),
      BGRA(Max(0, R-40), Max(0, G-40), Max(0, B-40), 255),
      gtLinear, PointF(CX, CY - 10), PointF(CX, CY + 45));

    ABitmap.FillPolyAntialias(CoverPts, GradScanner);
    ABitmap.DrawPolyLineAntialias(CoverPts, BGRA(0, 0, 0, 255), 1.5, True);

    // Highlight Cover Plastik
    ABitmap.DrawLineAntialias(CX - 15, CY - 5, CX - 13, CY + 40, BGRA(255, 255, 255, 120), 2.0);
    ABitmap.DrawLineAntialias(CX - 15, CY - 5, CX + 15, CY - 5, BGRA(255, 255, 255, 120), 2.0);
  end;

  // Poros Engsel (Metal Hinge Pin)
  ABitmap.DrawLineAntialias(CX - 22, CY - 10, CX + 22, CY - 10, BGRA(200, 200, 200, 255), 3.0);
  ABitmap.DrawLineAntialias(CX - 22, CY - 11, CX + 22, CY - 11, BGRA(0, 0, 0, 150), 1.0);
  ABitmap.DrawLineAntialias(CX - 22, CY - 9, CX + 22, CY - 9, BGRA(0, 0, 0, 150), 1.0);
end;

end.
