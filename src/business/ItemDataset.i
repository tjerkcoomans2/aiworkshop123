/*------------------------------------------------------------------------
  File        : ItemDataset.i
  Purpose     : Dataset definition for Item entity
  Syntax      : {business/ItemDataset.i}
  Description : Defines temp-table ttItem (before-table bttItem) and dataset
                dsItem, mirroring the sports2000 Item table
  Author(s)   : Tjerk Coomans
  Created     : Thu Oct 01 16:30:00 CEST 2026
  Notes       : Included by ItemEntity and by UI code that uses the entity
----------------------------------------------------------------------*/

/* Define temp-table for Item */
DEFINE TEMP-TABLE ttItem BEFORE-TABLE bttItem
    FIELD Itemnum AS INTEGER FORMAT "zzzzzzzzz9" INITIAL "0" LABEL "Item Num" COLUMN-LABEL "Item Num"
    FIELD ItemName AS CHARACTER FORMAT "x(25)" LABEL "Item Name" COLUMN-LABEL "Item Name"
    FIELD Price AS DECIMAL FORMAT "->,>>>,>>9.99" INITIAL "0" LABEL "Price" COLUMN-LABEL "Price"
    FIELD Onhand AS INTEGER FORMAT "->>>>9" INITIAL "0" LABEL "On Hand" COLUMN-LABEL "On Hand"
    FIELD Allocated AS INTEGER FORMAT "->>>>9" INITIAL "0" LABEL "Allocated" COLUMN-LABEL "Allocated"
    FIELD ReOrder AS INTEGER FORMAT "->>>>9" INITIAL "0" LABEL "Re Order" COLUMN-LABEL "Re Order"
    FIELD OnOrder AS INTEGER FORMAT "->>>>9" INITIAL "0" LABEL "On Order" COLUMN-LABEL "On Order"
    FIELD CatPage AS INTEGER FORMAT ">>9" INITIAL "0" LABEL "Cat Page" COLUMN-LABEL "Cat Page"
    FIELD CatDescription AS CHARACTER FORMAT "X(200)" LABEL "Cat-Description" COLUMN-LABEL "Cat-Description"
    FIELD Category1 AS CHARACTER FORMAT "x(30)" LABEL "Category1" COLUMN-LABEL "Category1"
    FIELD Category2 AS CHARACTER FORMAT "x(30)" LABEL "Category2" COLUMN-LABEL "Category2"
    FIELD Special AS CHARACTER FORMAT "x(8)" LABEL "Special" COLUMN-LABEL "Special"
    FIELD Weight AS DECIMAL FORMAT "->>,>>9.99" INITIAL "0" LABEL "Weight" COLUMN-LABEL "Weight"
    FIELD Minqty AS INTEGER FORMAT "->>>>9" INITIAL "0" LABEL "Min Qty" COLUMN-LABEL "Min Qty"
    INDEX ItemNum IS PRIMARY UNIQUE Itemnum ASCENDING.

/* Define dataset for Item */
DEFINE DATASET dsItem FOR ttItem.
