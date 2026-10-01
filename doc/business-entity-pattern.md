# ABL Business Entity Architecture Pattern

(Condensed version.)

## Overview

The Business Entity pattern provides a standardized, maintainable approach to data access in OpenEdge ABL applications. It separates UI logic from database operations through a layered architecture.

## Architecture Layers

1. **UI layer (windows/forms)** - user interaction and presentation. Never accesses database tables directly; calls Business Entity methods with datasets.
2. **Business Entity layer** - data access, business rules, validation. Extends `OpenEdge.BusinessLogic.BusinessEntity`; instantiated through `EntityFactory` (singleton).
3. **Database layer** - persistent storage, accessed only through data-sources attached to business entities.

## Key Components

### EntityFactory (Singleton)

Centralized management of business entity lifecycle.

```abl
CLASS business.EntityFactory:
    VAR PRIVATE STATIC EntityFactory objInstance.
    VAR PRIVATE CustomerEntity objCustomerEntityInstance.

    CONSTRUCTOR PRIVATE EntityFactory():
    END CONSTRUCTOR.

    METHOD PUBLIC STATIC EntityFactory GetInstance():
        IF objInstance = ? THEN
            objInstance = NEW EntityFactory().
        RETURN objInstance.
    END METHOD.

    METHOD PUBLIC CustomerEntity GetCustomerEntity():
        IF objCustomerEntityInstance = ? THEN
            objCustomerEntityInstance = NEW CustomerEntity().
        RETURN objCustomerEntityInstance.
    END METHOD.
END CLASS.
```

### Dataset Definition (.i include)

Defines the temp-tables and dataset used for data transfer; shared via include file.

```abl
DEFINE TEMP-TABLE ttCustomer BEFORE-TABLE bttCustomer
    FIELD CustNum AS INTEGER INITIAL "0" LABEL "Cust Num"
    FIELD Name AS CHARACTER LABEL "Name"
    /* ... additional fields ... */
    INDEX CustNum IS PRIMARY UNIQUE CustNum ASCENDING.

DEFINE DATASET dsCustomer FOR ttCustomer.
```

- `BEFORE-TABLE` enables change tracking for updates
- Primary index mirrors the database primary key

### Business Entity Class

```abl
CLASS business.CustomerEntity INHERITS BusinessEntity USE-WIDGET-POOL:

    {business/CustomerDataset.i}

    DEFINE DATA-SOURCE srcCustomer FOR Customer.

    CONSTRUCTOR PUBLIC CustomerEntity():
        SUPER(DATASET dsCustomer:HANDLE).

        VAR HANDLE[1] hDataSourceArray = DATA-SOURCE srcCustomer:HANDLE.
        VAR CHARACTER[1] cSkipListArray = [""].

        THIS-OBJECT:ProDataSource = hDataSourceArray.
        THIS-OBJECT:SkipList = cSkipListArray.
    END CONSTRUCTOR.

END CLASS.
```

Requirements:
- Inherit from `OpenEdge.BusinessLogic.BusinessEntity`
- Pass the dataset handle to the `SUPER()` constructor
- Assign data-source handles to `ProDataSource`
- `SkipList` array length matches the data-source array

## CRUD Operations

### Read

```abl
METHOD PUBLIC LOGICAL GetCustomerByNumber(INPUT ipiCustNum AS INTEGER,
                                          OUTPUT DATASET dsCustomer):
    VAR CHARACTER cFilter.
    VAR LOGICAL lFound = FALSE.

    cFilter = "WHERE Customer.CustNum = " + STRING(ipiCustNum).
    THIS-OBJECT:ReadData(cFilter).
    lFound = CAN-FIND(FIRST ttCustomer).

    RETURN lFound.
END METHOD.
```

Use `OUTPUT DATASET` **without** `BY-REFERENCE` for reads: `ReadData()` fills the entity's internal ProDataSet and OUTPUT copies the data back to the caller. `BY-REFERENCE` can cause a handle mismatch.

### Create / Update / Delete

```abl
METHOD PUBLIC VOID CreateCustomer(INPUT-OUTPUT DATASET dsCustomer):
    THIS-OBJECT:CreateData(DATASET dsCustomer BY-REFERENCE).
END METHOD.

METHOD PUBLIC VOID UpdateCustomer(INPUT-OUTPUT DATASET dsCustomer):
    THIS-OBJECT:UpdateData(DATASET dsCustomer BY-REFERENCE).
END METHOD.

METHOD PUBLIC VOID DeleteCustomer(INPUT-OUTPUT DATASET dsCustomer):
    THIS-OBJECT:DeleteData(DATASET dsCustomer BY-REFERENCE).
END METHOD.
```

Update from the UI:

```abl
lFound = objCustomerEntity:GetCustomerByNumber(iCustNum, OUTPUT DATASET dsCustomer).

IF lFound THEN DO:
    FIND FIRST ttCustomer.

    /* Enable change tracking */
    TEMP-TABLE ttCustomer:TRACKING-CHANGES = TRUE.

    ttCustomer.Name = "Updated Name".

    isValid = objCustomerEntity:ValidateCustomer(
        INPUT-OUTPUT DATASET dsCustomer BY-REFERENCE,
        OUTPUT cErrorMessage
    ).

    IF isValid THEN
        objCustomerEntity:UpdateCustomer(INPUT-OUTPUT DATASET dsCustomer BY-REFERENCE).
    ELSE
        MESSAGE cErrorMessage VIEW-AS ALERT-BOX.
END.
```

Steps: fetch with OUTPUT DATASET, enable `TRACKING-CHANGES`, modify the temp-table, validate, call the update method with `BY-REFERENCE`. Create works the same way with `CREATE ttCustomer`, delete with `DELETE ttCustomer`.

## Validation

```abl
METHOD PUBLIC LOGICAL ValidateCustomer(INPUT-OUTPUT DATASET dsCustomer,
                                     OUTPUT errorMessage AS CHARACTER):
    VAR LOGICAL isValid = TRUE.

    FIND FIRST ttCustomer NO-ERROR.
    IF AVAILABLE ttCustomer THEN DO:
        IF ttCustomer.Name = "" THEN DO:
            isValid = FALSE.
            errorMessage = "Customer name cannot be empty".
        END.
    END.

    RETURN isValid.
END METHOD.
```

- Always validate before create/update
- Return specific error messages for the UI

## Multi-Table Entities

For entities spanning several tables (e.g. Order + OrderLine), define one data-source per table and size the arrays accordingly:

```abl
DEFINE DATA-SOURCE srcOrder FOR Order.
DEFINE DATA-SOURCE srcOrderLine FOR OrderLine.

CONSTRUCTOR PUBLIC OrderEntity():
    SUPER(DATASET dsOrder:HANDLE).

    VAR HANDLE[2] hDataSourceArray.
    VAR CHARACTER[2] cSkipListArray.

    hDataSourceArray[1] = DATA-SOURCE srcOrder:HANDLE.
    hDataSourceArray[2] = DATA-SOURCE srcOrderLine:HANDLE.
    cSkipListArray[1] = "".
    cSkipListArray[2] = "".

    THIS-OBJECT:ProDataSource = hDataSourceArray.
    THIS-OBJECT:SkipList = cSkipListArray.
END CONSTRUCTOR.
```

```abl
DEFINE DATASET dsOrder FOR ttOrder, ttOrderLine
    DATA-RELATION OrderLines FOR ttOrder, ttOrderLine
        RELATION-FIELDS(OrderNum, OrderNum).
```

## UI Integration

```abl
USING business.CustomerEntity FROM PROPATH.
USING business.EntityFactory FROM PROPATH.

{business/CustomerDataset.i}

ON CHOOSE OF GetCustomer IN FRAME DEFAULT-FRAME:
    VAR INTEGER iCustomerNumber = INTEGER(CustomerNumber:screen-value).
    VAR EntityFactory objFactory = EntityFactory:GetInstance().
    VAR CustomerEntity objCustomerEntity = objFactory:GetCustomerEntity().
    VAR LOGICAL lCustomerFound.

    lCustomerFound = objCustomerEntity:GetCustomerByNumber(
        iCustomerNumber,
        OUTPUT DATASET dsCustomer
    ).

    IF lCustomerFound THEN DO:
        FIND FIRST ttCustomer.
        IF AVAILABLE ttCustomer THEN DO:
            CustomerName = ttCustomer.Name.
            DISPLAY CustomerName WITH FRAME {&frame-name}.
        END.
    END.
    ELSE
        MESSAGE "Customer not found" VIEW-AS ALERT-BOX.
END.
```

## Common Pitfalls

1. **BY-REFERENCE on OUTPUT DATASET for reads** - causes handle mismatch; use plain `OUTPUT DATASET dsCustomer`.
2. **Forgetting change tracking** - set `TEMP-TABLE ttCustomer:TRACKING-CHANGES = TRUE` before modifying, otherwise changes are not detected.
3. **Missing ProDataSource assignment** - defining the data-source is not enough; assign its handle to `ProDataSource` (and set `SkipList`) in the constructor.
4. **Direct database access from the UI** - go through the business entity and read from the temp-table instead.
5. **Not using named buffers** - always access database tables through a named buffer:

```abl
DEFINE BUFFER bCustomer FOR Customer.

FOR EACH bCustomer WHERE bCustomer.Country = 'USA':
    /* ... */
END.
```

## Refactoring Legacy Code

1. **Identify data access patterns** - direct FIND/FOR EACH statements, table usage in UI code, scattered validation, duplicated data access.
2. **Create the dataset definition** - `business/<Entity>Dataset.i` with a `tt<TableName>` temp-table (BEFORE-TABLE, fields, primary index) and a `ds<Entity>` dataset.
3. **Create the business entity class** - `business/<Entity>Entity.cls` inheriting `BusinessEntity`, including the dataset, defining the data-source and assigning `ProDataSource`/`SkipList`.
4. **Add the entity to the factory** - instance variable, `Get<Entity>Entity()` getter with lazy initialization, and cleanup in the reset method.
5. **Refactor the UI code** - replace direct database access with entity calls and temp-table reads.
6. **Extract validation logic** - move UI checks into a `Validate<Entity>` method returning a LOGICAL plus error message.
7. **Test incrementally** - start with a read operation in one UI component, then add create/update/delete and validation, one component at a time.

## Benefits

- **Maintainability** - centralized data access, clear separation of concerns
- **Reusability** - entities and validation shared across UI components
- **Testability** - business logic isolated from the UI
- **Consistency** - uniform data access, error handling and validation
- **Scalability** - easy to add entities and multi-table relationships

## References

- OpenEdge Documentation: Business Entity Class
- ABL Reference: Dataset and Temp-Table Definitions
- Project examples:
  - `src/business/CustomerEntity.cls`
  - `src/business/EntityFactory.cls`
  - `src/CustomerWin.w`
