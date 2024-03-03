program CurrencyConverterApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {FrmMain},
  Secret in 'Secret.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
