// *************************************************************************** }
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2020 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

unit MVCFramework.SQLGenerators.MySQL;

interface

uses
  FireDAC.Phys.MySQLDef,
  FireDAC.Phys.MySQL,
  System.Rtti,
  System.Generics.Collections,
  MVCFramework.RQL.Parser,
  MVCFramework.ActiveRecord,
  MVCFramework.Commons;

type
  TMVCSQLGeneratorMySQL = class(TMVCSQLGenerator)
  protected
    function GetCompilerClass: TRQLCompilerClass; override;
  public
    function CreateSelectSQL(
      const TableName: string;
      const Map: TFieldsMap;
      const PKFieldName: string;
      const PKOptions: TMVCActiveRecordFieldOptions): string; override;
    function CreateInsertSQL(
      const TableName: string;
      const Map: TFieldsMap;
      const PKFieldName: string;
      const PKOptions: TMVCActiveRecordFieldOptions): string; override;
    function CreateUpdateSQL(
      const TableName: string;
      const Map: TFieldsMap;
      const PKFieldName: string;
      const PKOptions: TMVCActiveRecordFieldOptions): string; override;
    function CreateDeleteSQL(
      const TableName: string;
      const Map: TFieldsMap;
      const PKFieldName: string;
      const PKOptions: TMVCActiveRecordFieldOptions): string; override;
    function CreateDeleteAllSQL(
      const TableName: string): string; override;
    function CreateSelectByPKSQL(
      const TableName: string;
      const Map: TFieldsMap; const PKFieldName: string;
      const PKOptions: TMVCActiveRecordFieldOptions): string; override;
    function CreateSQLWhereByRQL(
      const RQL: string;
      const Mapping: TMVCFieldsMapping;
      const UseArtificialLimit: Boolean = True): string; override;
    function CreateSelectCount(
      const TableName: string): string; override;
  end;

implementation

uses
  System.SysUtils,
  MVCFramework.RQL.AST2MySQL;

function TMVCSQLGeneratorMySQL.CreateInsertSQL(const TableName: string; const Map: TFieldsMap;
  const PKFieldName: string; const PKOptions: TMVCActiveRecordFieldOptions): string;
var
  lKeyValue: TPair<TRttiField, TFieldInfo>;
  lSB: TStringBuilder;
begin
  lSB := TStringBuilder.Create;
  try
    lSB.Append('INSERT INTO ' + TableName + '(');
    if (not(TMVCActiveRecordFieldOption.foAutoGenerated in PKOptions)) and (PKFieldName <> '') then
    begin
      lSB.Append(PKFieldName + ',');
    end;
    for lKeyValue in Map do
    begin
      if lKeyValue.Value.Writeable then
      begin
        lSB.Append(lKeyValue.Value.FieldName + ',');
      end;
    end;

    lSB.Remove(lSB.Length - 1, 1);
    lSB.Append(') values (');
    if (not(TMVCActiveRecordFieldOption.foAutoGenerated in PKOptions)) and (PKFieldName <> '') then
    begin
      lSB.Append(':' + PKFieldName + ',');
    end;
    for lKeyValue in Map do
    begin
      if lKeyValue.Value.Writeable then
      begin
        lSB.Append(':' + lKeyValue.Value.FieldName + ',');
      end;
    end;
    lSB.Remove(lSB.Length - 1, 1);
    lSB.Append(')');

    if TMVCActiveRecordFieldOption.foAutoGenerated in PKOptions then
    begin
      lSB.Append(';SELECT LAST_INSERT_ID() as ' + PKFieldName);
    end;
    Result := lSB.ToString;
  finally
    lSB.Free;
  end;
end;

function TMVCSQLGeneratorMySQL.CreateSelectByPKSQL(
  const TableName: string;
  const Map: TFieldsMap; const PKFieldName: string;
  const PKOptions: TMVCActiveRecordFieldOptions): string;
begin
  Result := CreateSelectSQL(TableName, Map, PKFieldName, PKOptions) + ' WHERE ' +
    PKFieldName + '= :' + PKFieldName; // IntToStr(PrimaryKeyValue);
end;

function TMVCSQLGeneratorMySQL.CreateSelectCount(
  const TableName: string): string;
begin
  Result := 'SELECT count(*) FROM ' + TableName;
end;

function TMVCSQLGeneratorMySQL.CreateSelectSQL(const TableName: string;
  const Map: TFieldsMap; const PKFieldName: string;
  const PKOptions: TMVCActiveRecordFieldOptions): string;
begin
  Result := 'SELECT ' + TableFieldsDelimited(Map, PKFieldName, ',') + ' FROM ' + TableName;
end;

function TMVCSQLGeneratorMySQL.CreateSQLWhereByRQL(
  const RQL: string;
  const Mapping: TMVCFieldsMapping;
  const UseArtificialLimit: Boolean = True): string;
var
  lMySQLCompiler: TRQLMySQLCompiler;
begin
  lMySQLCompiler := TRQLMySQLCompiler.Create(Mapping);
  try
    GetRQLParser.Execute(RQL, Result, lMySQLCompiler, UseArtificialLimit);
  finally
    lMySQLCompiler.Free;
  end;
end;

function TMVCSQLGeneratorMySQL.CreateUpdateSQL(const TableName: string; const Map: TFieldsMap;
  const PKFieldName: string; const PKOptions: TMVCActiveRecordFieldOptions): string;
var
  lKeyValue: TPair<TRttiField, TFieldInfo>;
begin
  Result := 'UPDATE ' + TableName + ' SET ';
  for lKeyValue in Map do
  begin
    if lKeyValue.Value.Writeable then
    begin
      Result := Result + lKeyValue.Value.FieldName + ' = :' + lKeyValue.Value.FieldName + ',';
    end;
  end;
  Result[Length(Result)] := ' ';
  if not PKFieldName.IsEmpty then
  begin
    Result := Result + ' where ' + PKFieldName + '= :' + PKFieldName;
  end;
end;

function TMVCSQLGeneratorMySQL.GetCompilerClass: TRQLCompilerClass;
begin
  Result := TRQLMySQLCompiler;
end;

function TMVCSQLGeneratorMySQL.CreateDeleteAllSQL(
  const TableName: string): string;
begin
  Result := 'DELETE FROM ' + TableName;
end;

function TMVCSQLGeneratorMySQL.CreateDeleteSQL(const TableName: string; const Map: TFieldsMap;
  const PKFieldName: string; const PKOptions: TMVCActiveRecordFieldOptions): string;
begin
  Result := CreateDeleteAllSQL(TableName) + ' WHERE ' + PKFieldName + '=:' + PKFieldName;
end;

initialization

TMVCSQLGeneratorRegistry.Instance.RegisterSQLGenerator('mysql', TMVCSQLGeneratorMySQL);

finalization

TMVCSQLGeneratorRegistry.Instance.UnRegisterSQLGenerator('mysql');

end.
