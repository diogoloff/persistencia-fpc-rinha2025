program RinhaPersistencia;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, unLinux, unServer, unGenerica, unAPI
  { you can add units after this };

type

  { TRinhaPersistencia }

  TRinhaPersistencia = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TRinhaPersistencia }

procedure TRinhaPersistencia.DoRun;
begin
  {$IFDEF SERVICO}
    if (Trim(UpperCase(Copy(ParamStr(1), 1, 6))) <> '-PATH:') then
    begin
      GerarLog('Parâmetro inválido. Use -PATH:<caminho da aplicação>');
      Exit;
    end;

    FPathAplicacao := Trim(Copy(ParamStr(1), 7, Length(ParamStr(1)) - 6));

    if (Trim(FPathAplicacao) = '') then
    begin
      GerarLog('Caminho da aplicação não informado.');
      Exit;
    end;
  {$ENDIF}

  try
     if (FindCmdLineSwitch('DAEMON', ['-'], true)) then
     begin
       TPosixDaemon.Setup(nil);

       RunServer;

       if (not FServerIniciado) then
          Halt(TPosixDaemon.EXIT_FAILURE);

       FPidFile:= '';
       if (FindCmdLineSwitch('pidfile', ['-'], true)) then
       begin
         FPidFile:= Trim(ParamStr(5));
         TPosixDaemon.CreatePIDFile(FPidFile);
       end;

       TPosixDaemon.Run(1000, nil);

       StopServer;

       if (Trim(FPidFile) <> '') then
         TPosixDaemon.RemovePIDFile(FPidFile);
     end
     else
     begin
       writeln('RinhaPersistencia iniciada como aplicação.');
       RunServer;
       writeln('RinhaPersistencia finalizada!');
     end;
  except
    on E: Exception do
      GerarLog(E.ClassName + ': ' + E.Message, True);
  end;

  // stop program loop
  Terminate;
end;

constructor TRinhaPersistencia.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TRinhaPersistencia.Destroy;
begin
  inherited Destroy;
end;

procedure TRinhaPersistencia.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  Application: TRinhaPersistencia;
begin
  Application:=TRinhaPersistencia.Create(nil);
  Application.Title:='RinhaPersistencia';
  Application.Run;
  Application.Free;
end.

