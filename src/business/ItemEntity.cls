/*------------------------------------------------------------------------
  File        : ItemEntity
  Purpose     : Business Entity for Item data access
  Syntax      : 
  Description : 
  Author(s)   : 
  Created     : Thu Oct 01 16:30:00 CEST 2026
  Notes       : 
----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.BusinessLogic.BusinessEntity.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS business.ItemEntity INHERITS BusinessEntity USE-WIDGET-POOL:
    
    /* Maximum total value (on hand * price) allowed for an item */
    &SCOPED-DEFINE MAX-ONHAND-VALUE 6000
    
    /* Include dataset definition */
    {business/ItemDataset.i}
    
    /* Named buffer for database access */
    DEFINE PRIVATE BUFFER bItem FOR Item.
    
    /* Define data sources */
    DEFINE DATA-SOURCE srcItem FOR bItem.
    
    /*------------------------------------------------------------------------------
     Purpose: Constructor for ItemEntity
     Notes:
    ------------------------------------------------------------------------------*/
    CONSTRUCTOR PUBLIC ItemEntity():
        SUPER(DATASET dsItem:HANDLE).

        VAR HANDLE[1] hDataSourceArray = DATA-SOURCE srcItem:HANDLE.
        VAR CHARACTER[1] cSkipListArray = [""].
        
        /* Data Source for each table in dataset */
        THIS-OBJECT:ProDataSource = hDataSourceArray.
        /* Skip-list entry for each table in dataset */
        THIS-OBJECT:SkipList = cSkipListArray.
    END CONSTRUCTOR.
    
    /*------------------------------------------------------------------------------
     Purpose: Get item by item number
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC LOGICAL GetItemByNumber(INPUT ipiItemNum AS INTEGER,
                                          OUTPUT DATASET dsItem):
        VAR CHARACTER cFilter.
        VAR LOGICAL lFound = FALSE.
        
        /* Build filter for item number */
        cFilter = "WHERE bItem.Itemnum = " + STRING(ipiItemNum).
        
        /* Read data using filter */
        THIS-OBJECT:ReadData(cFilter).
    
        /* Check if item was found */
        lFound = CAN-FIND(FIRST ttItem).
        
        RETURN lFound.
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose: Create item data
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID CreateItem(INPUT-OUTPUT DATASET dsItem):
        /* Create data in database */
        THIS-OBJECT:CreateData(DATASET dsItem BY-REFERENCE).
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose: Update item data
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID UpdateItem(INPUT-OUTPUT DATASET dsItem):
        /* Update data in database */
        THIS-OBJECT:UpdateData(DATASET dsItem BY-REFERENCE).
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose: Delete item data
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID DeleteItem(INPUT-OUTPUT DATASET dsItem):
        /* Delete data from database */
        THIS-OBJECT:DeleteData(DATASET dsItem BY-REFERENCE).
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose: Validate item data
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC LOGICAL ValidateItem(INPUT-OUTPUT DATASET dsItem,
                                       OUTPUT errorMessage AS CHARACTER):
        VAR LOGICAL isValid = TRUE.
        VAR DECIMAL dTotal.
        
        /* Find the first item in the dataset */
        FIND FIRST ttItem NO-ERROR.
        IF AVAILABLE ttItem THEN DO:
            dTotal = ttItem.Onhand * ttItem.Price.
            
            /* Validate item price */
            IF ttItem.Price = 0 THEN DO:
                isValid = FALSE.
                errorMessage = "Price cannot be empty".
            END.
            /* Validate total value on hand */
            ELSE IF dTotal > {&MAX-ONHAND-VALUE} THEN DO:
                isValid = FALSE.
                errorMessage = SUBSTITUTE("Total value onhand will be &1, should not be larger than &2",
                                          dTotal, {&MAX-ONHAND-VALUE}).
            END.
        END.
        
        RETURN isValid.
    END METHOD.

END CLASS.
