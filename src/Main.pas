unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Styles.Objects, Data.DB, Datasnap.DBClient,
  FMX.ListBox, FMX.Edit, System.JSON, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, System.DateUtils, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL;

type
  TCurrency = record
    Code: string;
    Name: string;
  end;

type
  TFrmMain = class(TForm)
    Header: TToolBar;
    HeaderLabel: TLabel;
    CmbBaseCurrency: TComboBox;
    EdtBaseCurrency: TEdit;
    CmbTargetCurrency: TComboBox;
    EdtTargetCurrency: TEdit;
    HTTP: TIdHTTP;
    LblLastUpdate: TLabel;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    procedure FormCreate(Sender: TObject);
    procedure EdtBaseCurrencyChange(Sender: TObject);
    procedure EdtTargetCurrencyChange(Sender: TObject);
    procedure CmbTargetCurrencyChange(Sender: TObject);
  private
    { Private declarations }
    Currencies: array of TCurrency;
    APIResponse: string;

    ExchangeRateAPI: TJSONObject;
    ConversionRates: TJSONObject;
    ConversionRate: Double;
    UnixTimeStamp: Integer;
    UpdateDateTime: TDateTime;
    FormattedDate: string;
  public
    { Public declarations }
    procedure HandleExchangeRateResponse(const Response: string);
    function GetBaseCurencyCode: string;
  end;

var
  FrmMain: TFrmMain;
implementation

uses
  Secret;

{$R *.fmx}

procedure TFrmMain.CmbTargetCurrencyChange(Sender: TObject);
begin
  if APIResponse <> EmptyStr then
  begin
    HandleExchangeRateResponse(APIResponse);
    EdtTargetCurrency.Text := FloatToStr(StrToFloat(EdtBaseCurrency.Text)*ConversionRate);
  end;
end;

procedure TFrmMain.EdtBaseCurrencyChange(Sender: TObject);
begin
  if ConversionRate > 0 then
    EdtTargetCurrency.Text := FloatToStr(StrToFloat(EdtBaseCurrency.Text)*ConversionRate);
end;

procedure TFrmMain.EdtTargetCurrencyChange(Sender: TObject);
begin
  if ConversionRate > 0 then
    EdtBaseCurrency.Text := FloatToStr(StrToFloat(EdtTargetCurrency.Text)/ConversionRate);
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  APIResponse := EmptyStr;
  ConversionRate := 0;

  SetLength(Currencies, 5);

  Currencies[0].Code := 'BRL';
  Currencies[0].Name := 'Real Brasileiro';

  Currencies[1].Code := 'USD';
  Currencies[1].Name := 'Dólar (EUA)';

  Currencies[2].Code := 'EUR';
  Currencies[2].Name := 'Euro';

  Currencies[3].Code := 'GBP';
  Currencies[3].Name := 'Libra Esterlina';

  Currencies[4].Code := 'JPY';
  Currencies[4].Name := 'Iene (Japão)';

  for var Currency in Currencies do
  begin
    CmbBaseCurrency.Items.Add(Currency.Name);
    CmbTargetCurrency.Items.Add(Currency.Name);
  end;

  CmbBaseCurrency.ItemIndex := 0;
  CmbTargetCurrency.ItemIndex := 1;

  EdtBaseCurrency.Text := '1';

  APIResponse := HTTP.Get('https://v6.exchangerate-api.com/v6/' + APIKey + '/latest/' + GetBaseCurencyCode);
  HandleExchangeRateResponse(APIResponse);
  EdtTargetCurrency.Text := FloatToStr(StrToFloat(EdtBaseCurrency.Text)*ConversionRate);
end;

function TFrmMain.GetBaseCurencyCode: string;
var
  SelectedIndex: Integer;
begin
  SelectedIndex := CmbBaseCurrency.ItemIndex;
  if (SelectedIndex >=0) and (SelectedIndex < Length(Currencies)) then
    Result := Currencies[SelectedIndex].Code
  else
    Result := 'BRL';

end;

procedure TFrmMain.HandleExchangeRateResponse(const Response: string);
begin
  ExchangeRateAPI := TJSONObject.ParseJSONValue(Response) as TJSONObject;
  try
    try
      if ExchangeRateAPI.GetValue('result').Value = 'success' then
      begin
        ConversionRates := TJSONObject.ParseJSONValue('conversion_rates') as TJSONObject;
        ConversionRate := ConversionRates.GetValue(GetBaseCurencyCode).Value.ToDouble;

        UnixTimeStamp := ExchangeRateAPI.GetValue('time_last_update_unix').Value.ToInteger;
        UpdateDateTime := UnixToDateTime(UnixTimeStamp);
        FormattedDate := FormatDateTime('dd/mm/yyyy hh:mm', UpdateDateTime);
        LblLastUpdate.Text := 'Última atualização (UTC): ' + FormattedDate;
      end
      else
      begin
        raise Exception.Create(ExchangeRateAPI.GetValue('error-type').Value);
      end;
    except
      on E: Exception do
      begin
        ConversionRate := 1;
        FormattedDate := FormatDateTime('dd/mm/yyyy hh:mm', Now);
        LblLastUpdate.Text := 'Última atualização: ' + FormattedDate;
        CmbBaseCurrency.ItemIndex := 0;
        CmbTargetCurrency.ItemIndex := 1;
        ShowMessage(E.Message);
      end;
    end;
  finally

  end;
end;

end.
