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

unit MVCFramework.SQLGenerators.PostgreSQL;

interface

uses
  System.Rtti,
  System.Generics.Collections,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  MVCFramework.ActiveRecord,
  MVCFramework.Commons,
  MVCFramework.RQL.Parser;

type
  TMVCSQLGeneratorPostgreSQL = class(TMVCSQLGenerator)
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
    function GetSequenceValueSQL(const PKFieldName: string;
      const SequenceName: string;
      const Step: Integer = 1): string; override;
  end;

implementation

{
  All identifiers (including column names) that are not double-quoted are folded to
  lower case in PostgreSQL. Column names that were created with double-quotes and thereby
  retained upper-case letters (and/or other syntax violations) have to be double-quoted
  for the rest of their life.
}

uses
  System.SysUtils,
  MVCFramework.RQL.AST2PostgreSQL;

function TMVCSQLGeneratorPostgreSQL.CreateInsertSQL(const TableName: string; const Map: TFieldsMap;
  const PKFieldName: string; const PKOptions: TMVCActiveRecordFieldOptions): string;
var
  lKeyValue: TPair<TRttiField, TFieldInfo>;
  lSB: TStringBuilder;
begin
  lSB := TStringBuilder.Create;
  try
    lSB.Append('INSERT INTO ' + TableName + ' (');
    if not(TMVCActiveRecordFieldOption.foAutoGenerated in PKOptions) then
    begin
      lSB.Append(PKFieldName + ',');
    end;

    for lKeyValue in Map do
    begin
      // if not(foTransient in lKeyValue.Value.FieldOptions) then
      if lKeyValue.Value.Writeable then
      begin
        lSB.Append(lKeyValue.Value.FieldName + ',');
      end;
    end;
    lSB.Remove(lSB.Length - 1, 1);
    lSB.Append(') values (');
    if not(TMVCActiveRecordFieldOption.foAutoGenerated in PKOptions) then
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
      lSB.Append(' RETURNING ' + PKFieldName);
    end;
    Result := lSB.ToString;
  finally
    lSB.Free;
  end;
end;

function TMVCSQLGeneratorPostgreSQL.CreateSelectByPKSQL(
      const TableName: string;
      const Map: TFieldsMap; const PKFieldName: string;
      const PKOptions: TMVCActiveRecordFieldOptions): string;
begin
  Result := CreateSelectSQL(TableName, Map, PKFieldName, PKOptions) + ' WHERE ' +
    PKFieldName + '= :' + PKFieldName; // IntToStr(PrimaryKeyValue);
end;

function TMVCSQLGeneratorPostgreSQL.CreateSelectCount(
  const TableName: string): string;
begin
  Result := 'SELECT count(*) FROM ' + TableName;
end;

function TMVCSQLGeneratorPostgreSQL.CreateSelectSQL(const TableName: string;
  const Map: TFieldsMap; const PKFieldName: string;
  const PKOptions: TMVCActiveRecordFieldOptions): string;
begin
  Result := 'SELECT ' + TableFieldsDelimited(Map, PKFieldName, ',') + ' FROM ' + TableName;
end;

function TMVCSQLGeneratorPostgreSQL.CreateSQLWhereByRQL(
  const RQL: string;
  const Mapping: TMVCFieldsMapping;
  const UseArtificialLimit: Boolean): string;
var
  lPostgreSQLCompiler: TRQLPostgreSQLCompiler;
begin
  lPostgreSQLCompiler := TRQLPostgreSQLCompiler.Create(Mapping);
  try
    GetRQLParser.Execute(RQL, Result, lPostgreSQLCompiler, UseArtificialLimit);
  finally
    lPostgreSQLCompiler.Free;
  end;
end;

function TMVCSQLGeneratorPostgreSQL.CreateUpdateSQL(const TableName: string; const Map: TFieldsMap;
  const PKFieldName: string; const PKOptions: TMVCActiveRecordFieldOptions): string;
var
  lPair: TPair<TRttiField, TFieldInfo>;
begin
  Result := 'UPDATE ' + TableName + ' SET ';
  for lPair in Map do
  begin
    if lPair.Value.Writeable then
    begin
      Result := Result + lPair.Value.FieldName + ' = :' + lPair.Value.FieldName + ',';
    end;
  end;
  Result[Length(Result)] := ' ';
  if not PKFieldName.IsEmpty then
  begin
    Result := Result + ' where ' + PKFieldName + '= :' + PKFieldName;
  end;
end;

function TMVCSQLGeneratorPostgreSQL.GetCompilerClass: TRQLCompilerClass;
begin
  Result := TRQLPostgreSQLCompiler;
end;

function TMVCSQLGeneratorPostgreSQL.GetSequenceValueSQL(const PKFieldName,
  SequenceName: string; const Step: Integer): string;
begin
  Result := Format('SELECT nextval(''%s'') %s', [SequenceName, PKFieldName]);
end;

function TMVCSQLGeneratorPostgreSQL.CreateDeleteAllSQL(
  const TableName: string): string;
begin
  Result := 'DELETE FROM ' + TableName;
end;

function TMVCSQLGeneratorPostgreSQL.CreateDeleteSQL(const TableName: string; const Map: TFieldsMap;
  const PKFieldName: string; const PKOptions: TMVCActiveRecordFieldOptions): string;
begin
  Result := CreateDeleteAllSQL(TableName) + ' WHERE ' + PKFieldName + '=:' + PKFieldName;
end;

initialization

TMVCSQLGeneratorRegistry.Instance.RegisterSQLGenerator('postgresql', TMVCSQLGeneratorPostgreSQL);

finalization

TMVCSQLGeneratorRegistry.Instance.UnRegisterSQLGenerator('postgresql');

end.
