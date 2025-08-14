unit unGenerica;

{$mode ObjFPC}{$H+}

interface

uses
    SysUtils,
    SyncObjs,
    DateUtils,
    mormot.core.base,
    mormot.core.data;

procedure CarregarVariaveisAmbiente;
function GetEnv(const lsEnvVar, lsDefault: string): string;
procedure GerarLog(lsMsg: String; lbForca: Boolean = False);

var
    FPathAplicacao: String;
    FServerIniciado: Boolean;
    FPidFile: String;
    FLogLock: TCriticalSection;
    FDebug: Boolean;
    FNumMaxWorkersSocket: Integer;

const
    cTransacaoPath = '/opt/rinha/transacoes/';

implementation

function GetEnv(const lsEnvVar, lsDefault: string): string;
begin
    Result := GetEnvironmentVariable(lsEnvVar);
    if Result = '' then
        Result := lsDefault;
end;

procedure AppendStrToFile(const AFileName, ATextToAppend: string);
var
    lF: TextFile;
begin
    AssignFile(lF, AFileName);

    try
        if FileExists(AFileName) then
            Append(lF)
        else
            Rewrite(lF);

        Writeln(lF, ATextToAppend);
    finally
        CloseFile(lF);
    end;
end;

procedure GerarLog(lsMsg: String; lbForca: Boolean);
var
    lsArquivo: String;
    lsData: String;
begin
    {$IFNDEF DEBUG}
    if (not FDebug) and (not lbForca) then
        Exit;
    {$ENDIF}

    {$IFNDEF SERVICO}
    WriteLn(lsMsg);
    {$ENDIF}

    FLogLock.Enter;
    try
        try
            if Trim(FPathAplicacao) = '' then
                FPathAplicacao := '/opt/rinha/';

            lsData := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now);
            lsArquivo := FPathAplicacao + 'Logs' + PathDelim + 'log' + FormatDateTime('ddmmyyyy', Date) + '.txt';
            AppendStrToFile(lsArquivo, lsData + ':' + lsMsg);
        except
        end;
    finally
        FLogLock.Leave;
    end;
end;

procedure CarregarVariaveisAmbiente;
begin
    FDebug := GetEnv('DEBUG', 'N') = 'S';
    FNumMaxWorkersSocket := StrToIntDef(GetEnv('NUM_WORKERS_SOCKET', ''), 32);

    if (FNumMaxWorkersSocket < 0) then
        FNumMaxWorkersSocket:= 1;
end;

initialization
    FLogLock := TCriticalSection.Create;

finalization
    FLogLock.Free;

end.

