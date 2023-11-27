unit Entities;

interface

uses
  MVCFramework.Serializer.Commons,
  MVCFramework.ActiveRecord,
  MVCFramework.Nullables,
  System.Classes,
  System.DateUtils,
  MVCFramework,
  MVCFramework.Utils,
  System.Generics.Collections;

type

  [MVCNameCase(ncCamelCase)]
  [MVCTable('people')]
  [MVCEntityActions([eaCreate, eaRetrieve, eaUpdate, eaDelete])]
  TPerson = class(TMVCActiveRecord)
  private
    [MVCTableField('id', [foPrimaryKey, foAutoGenerated])]
    fID: Int64;
    [MVCTableField('LAST_NAME')]
    fLastName: string;
    [MVCTableField('FIRST_NAME')]
    fFirstName: string;
    [MVCTableField('DOB')]
    fDOB: NullableTDate;
    [MVCTableField('FULL_NAME')]
    fFullName: string;
    [MVCTableField('IS_MALE')]
    fIsMale: NullableBoolean;
    [MVCTableField('NOTE')]
    fNote: string;
    [MVCTableField('PHOTO')]
    fPhoto: TStream;

    // transient fields
    fAge: NullableInt32;

    procedure SetLastName(const Value: string);
    procedure SetID(const Value: Int64);
    procedure SetFirstName(const Value: string);
    procedure SetDOB(const Value: NullableTDate);
    function GetFullName: string;
    procedure SetIsMale(const Value: NullableBoolean);
    procedure SetNote(const Value: string);
  protected
    procedure OnAfterLoad; override;
    procedure OnBeforeInsertOrUpdate; override;
    procedure OnValidation(const Action: TMVCEntityAction); override;
    procedure OnBeforeInsert; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function GetUniqueString: String;
    procedure Assign(ActiveRecord: TMVCActiveRecord); override;
    property ID: Int64 read fID write SetID;
    [MVCNameAs('person_surname')]
    property LastName: string read fLastName write SetLastName;
    [MVCNameAs('person_name')]
    property FirstName: string read fFirstName write SetFirstName;
    property Age: NullableInt32 read fAge;
    property DOB: NullableTDate read fDOB write SetDOB;
    property FullName: string read GetFullName;
    property IsMale: NullableBoolean read fIsMale write SetIsMale;
    property Note: string read fNote write SetNote;
    property Photo: TStream read fPhoto;
  end;

  [MVCNameCase(ncLowerCase)]
  [MVCTable('phones')]
  [MVCEntityActions([eaCreate, eaRetrieve, eaUpdate, eaDelete])]
  TPhone = class(TMVCActiveRecord)
  private
    [MVCTableField('id', [foPrimaryKey, foAutoGenerated])]
    fID: Integer;
    [MVCTableField('phone_number')]
    fPhoneNumber: string;
    [MVCTableField('number_type')]
    fNumberType: string;
    [MVCTableField('id_person')]
    fIDPerson: Integer;
  protected
    procedure OnValidation(const Action: TMVCEntityAction); override;
  public
    property ID: Integer read fID write fID;
    property IDPerson: Integer read fIDPerson write fIDPerson;
    property PhoneNumber: string read fPhoneNumber write fPhoneNumber;
    property NumberType: string read fNumberType write fNumberType;
  end;

  [MVCNameCase(ncLowerCase)]
  [MVCTable('PEOPLE')]
  [MVCEntityActions([eaCreate, eaRetrieve, eaUpdate, eaDelete])]
  TContact = class(TPerson)
  private
    function GetPhones: TObjectList<TPhone>;
  public
    property Phones: TObjectList<TPhone> read GetPhones;
  end;

  [MVCNameCase(ncLowerCase)]
  [MVCEntityActions([eaRetrieve])]
  [MVCNamedSQLQuery('AverageSalary',
    'select person_type, coalesce(avg(salary::numeric), 0) average_salary from people ' +
    'group by person_type order by 1', TMVCActiveRecordBackEnd.PostgreSQL)]
  TSalaryAggregate = class(TMVCActiveRecord)
  private
    [MVCTableField('average_salary')]
    FAverageSalary: Currency;
    [MVCTableField('person_type')]
    FPersonType: String;
    procedure SetAverageSalary(const Value: Currency);
    procedure SetPersonType(const Value: String);
  public
    property PersonType: String read FPersonType write SetPersonType;
    property AverageSalary: Currency read FAverageSalary write SetAverageSalary;
  end;


  [MVCNameCase(ncLowerCase)]
  [MVCTable('articles')]
  [MVCEntityActions([eaCreate, eaRetrieve, eaUpdate, eaDelete])]
  TArticle = class(TMVCActiveRecord)
  private
    [MVCTableField('id', [foPrimaryKey, foAutoGenerated])]
    fID: Int64;
    [MVCTableField('price')]
    FPrice: UInt32;
    [MVCTableField('description')]
    FDescription: string;
    procedure SetID(const Value: Int64);
    procedure SetDescription(const Value: string);
    procedure SetPrice(const Value: UInt32);
  public
    property ID: Int64 read fID write SetID;
    property Description: string read FDescription write SetDescription;
    property Price: UInt32 read FPrice write SetPrice;
  end;

  [MVCNameCase(ncLowerCase)]
  [MVCTable('customers_with_version')]
  TCustomersWithVersion = class(TMVCActiveRecord)
  private
    [MVCTableField('id', [foPrimaryKey, foAutoGenerated])]
    fID: Int64;
    [MVCTableField('code')]
    fCode: NullableString;
    [MVCTableField('description')]
    fDescription: NullableString;
    [MVCTableField('city')]
    fCity: NullableString;
    [MVCTableField('note')]
    fNote: NullableString;
    [MVCTableField('rating')]
    fRating: NullableInt32;
    [MVCTableField('objversion', [foVersion])]
    fObjversion: Integer;
  public
    property ID: Int64 read fID write fID;
    property Code: NullableString read fCode write fCode;
    property Description: NullableString read fDescription write fDescription;
    property City: NullableString read fCity write fCity;
    property Note: NullableString read fNote write fNote;
    property Rating: NullableInt32 read fRating write fRating;
    property ObjVersion: Integer read fObjversion write fObjversion;
  end;

implementation

uses
  System.SysUtils;

{ TPersona }

procedure TPerson.Assign(ActiveRecord: TMVCActiveRecord);
begin
  if ActiveRecord is TPerson then
  begin
    var lPerson := TPerson(ActiveRecord);
    Self.LastName := lPerson.LastName;
    Self.FirstName := lPerson.FirstName;
    Self.DOB := lPerson.DOB;
    Self.IsMale := lPerson.IsMale;
    Self.Note := lPerson.Note;
    Self.Photo.Size := 0;
    Self.Photo.CopyFrom(lPerson.Photo);
    Self.Photo.Position := 0;
  end
  else
    inherited;
end;

constructor TPerson.Create;
begin
  inherited;
  fPhoto := TMemoryStream.Create;
end;

destructor TPerson.Destroy;
begin
  fPhoto.Free;
  inherited;
end;

function TPerson.GetFullName: string;
begin
  Result := fFullName;
end;

function TPerson.GetUniqueString: String;
begin
  Result :=
    fID.ToString + '|' +
    fFirstName + '|' +
    fLastName + '|' +
    DateToISODate(fDOB.ValueOrDefault) + '|' +
    BoolToStr(fIsMale.ValueOrDefault, True) + '|' +
    GetSHA1HashFromStream(fPhoto);
end;

procedure TPerson.OnAfterLoad;
begin
  inherited;
  if fDOB.HasValue then
  begin
    fAge := YearsBetween(fDOB, now);
  end
  else
  begin
    fAge.Clear;
  end;
end;

procedure TPerson.OnBeforeInsert;
begin
  inherited;
end;

procedure TPerson.OnBeforeInsertOrUpdate;
begin
  inherited;
  fLastName := fLastName.ToUpper;
  fFirstName := fFirstName.ToUpper;
  fFullName := fFirstName + ' ' + fLastName;
end;

procedure TPerson.OnValidation(const Action: TMVCEntityAction);
begin
  inherited;
  if fLastName.Trim.IsEmpty or fFirstName.Trim.IsEmpty then
    raise EMVCActiveRecord.Create
      ('Validation error. FirstName and LastName are required');
end;

procedure TPerson.SetLastName(const Value: string);
begin
  fLastName := Value;
end;

procedure TPerson.SetNote(const Value: string);
begin
  fNote := Value;
end;

procedure TPerson.SetDOB(const Value: NullableTDate);
begin
  fDOB := Value;
end;

procedure TPerson.SetID(const Value: Int64);
begin
  fID := Value;
end;

procedure TPerson.SetIsMale(const Value: NullableBoolean);
begin
  fIsMale := Value;
end;

procedure TPerson.SetFirstName(const Value: string);
begin
  fFirstName := Value;
end;

{ TArticle }

procedure TArticle.SetDescription(const Value: string);
begin
  FDescription := Value;
end;

procedure TArticle.SetID(const Value: Int64);
begin
  fID := Value;
end;

procedure TArticle.SetPrice(const Value: UInt32);
begin
  FPrice := Value;
end;

{ TPhone }

procedure TPhone.OnValidation(const Action: TMVCEntityAction);
begin
  inherited;
  if fPhoneNumber.Trim.IsEmpty then
    raise EMVCActiveRecord.Create('Phone Number cannot be empty');
end;

{ TContact }

function TContact.GetPhones: TObjectList<TPhone>;
begin
  Result := TMVCActiveRecord.SelectRQL<TPhone>('eq(IDPerson, ' +
    self.ID.ToString + ')', 100);
end;

{ TSalaryAggregate }

procedure TSalaryAggregate.SetAverageSalary(const Value: Currency);
begin
  FAverageSalary := Value;
end;

procedure TSalaryAggregate.SetPersonType(const Value: String);
begin
  FPersonType := Value;
end;

initialization

ActiveRecordMappingRegistry.AddEntity('people', TPerson);
ActiveRecordMappingRegistry.AddEntity('salary', TSalaryAggregate);
ActiveRecordMappingRegistry.AddEntity('contacts', TContact);
ActiveRecordMappingRegistry.AddEntity('phones', TPhone);
ActiveRecordMappingRegistry.AddEntity('articles', TArticle);
ActiveRecordMappingRegistry.AddEntity('customers', TCustomersWithVersion);

finalization

end.
