/**
 * Copyright (c) 2014, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
 * GoogleSheetsExportListController
 */
public class GoogleSheetsExportListController
{
	//Statics
	private static final Integer BATCH_SIZE = 100;
	
	//Instance Variables
	public String recordTypeName { get; set; }
	
    public List<SelectOption> sheetSelectOptions { get; set; }
    public List<SelectOption> worksheetSelectOptions { get; set; }
    
    public String selectedSheetId { get; set; }
    public String selectedWorksheetId { get; set; }
    
    public String error { get; set; }
    
    private ApexPages.StandardSetController standardController;
     
    public List<SObject> listObjects { get; set; }
    
    public List<FieldWrapper> allFields { get; set; }
    public List<FieldWrapper> selectedFields { get; set; }
    
    public ConnectorService connectorService;
    
    /**
     * Constructor
     */
    public GoogleSheetsExportListController(ApexPages.StandardSetController controller)
    {
    	try
        {   
        	standardController = controller;
        	
        	connectorService = getConnectorService();
      
      		if (connectorService != null)
	        {
	        	String msg = connectorService.validateConnector();
	          	Boolean validConnector = String.isEmpty(msg);
	          	if (!validConnector)
	          	{
	            	error(msg);
	          	}
	          	else
	          	{
	        		findGoogleSheets();
	          	}
	        }
	        else
	        {
	        	error('Google sheets connector not found.');
	        }
   			
            error = ApexPages.currentPage().getParameters().get('error');
            if (error != null) 
            {
                error('Error: ' + error);
                return;
            }
            
            initialiseFieldList();
            preview();
        }
        catch (Exception ex)
        {
        	error('Error: ' + ex.getMessage());
        }
    }
    
    /**
     * Gets a valid connector for Google requests.
     *
     * Note: for separation of concerns consider using a selector pattern.
	 * See https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
     */
    private ConnectorService getConnectorService()
    {
    	if (connectorService == null)
    	{	
    		try
    		{
	    		Connector__c c = 
	    		[
	    			SELECT 
	    				c.TokenType__c, c.RefreshToken__c, c.RefreshTokenRequested__c, c.Name, c.Id, c.AccessToken__c, 
					   	c.AccessTokenRequested__c, c.AccessTokenExpiry__c, c.Active__c, 
					   	ConnectorType__r.TokenEndpoint__c, ConnectorType__r.Scope__c, ConnectorType__r.ScopeRequired__c, 
					   	ConnectorType__r.RedirectUri__c, ConnectorType__r.Name, ConnectorType__r.Id, 
					   	ConnectorType__r.ExtraUrlParameters__c, ConnectorType__r.DeveloperName__c, 
					   	ConnectorType__r.ClientSecret__c, ConnectorType__r.ClientId__c, ConnectorType__r.CallbackURL__c, 
					   	ConnectorType__r.AuthorizationEndpoint__c
	    			FROM Connector__c c
	    			WHERE ConnectorType__r.Name =: GoogleSheetsConfigure.SHEETS_TYPE_LABEL
	    			AND c.OwnerId =: UserInfo.getUserID()
	    			LIMIT 1
	    		];
	    		
	    		if (c != null)
	    		{
	    			connectorService = new ConnectorService(c);
	    		}
    		}
    		catch (Exception ex)
    		{
    		}
    	}
    	return connectorService;
    }
    
    /**
     * Finds all the fields related to the record, excluding linked object fields.
     */
    private void initialiseFieldList()
    {
    	SObject record = standardController.getRecord();
    	SObjectType recordType = record.getSObjectType();
    	DescribeSObjectResult recordTypeDescribe = recordType.getDescribe();
    	recordTypeName = recordTypeDescribe.getName();
    	
    	Map<String, SObjectField> fieldMaps = recordTypeDescribe.fields.getMap();
    	
    	List<String> fieldNames = new List<String>(fieldMaps.keySet());
    	fieldNames.sort();
    	
    	allFields = new List<FieldWrapper>();
    	
    	for (String name : fieldNames)
    	{
    		SObjectField field = fieldMaps.get(name);
    		
    		DescribeFieldResult fieldDescribe = field.getDescribe();
    		
    		String fieldLabel = fieldDescribe.getLabel();
    		String fieldName = fieldDescribe.getName();
       		if (fieldName.endsWith('__c'))
       		{
       			continue;
       		}
       		
       		//Default the selection to Id & Name
       		Boolean selected = name == 'Id' || name == 'Name';
   			allFields.add(new FieldWrapper(fieldLabel, fieldName, selected));
    	}	
   	}
   	
   	/**
   	 * Selects the required data for the selected objects, adding the data to the preview table.
   	 */
   	public void preview()
   	{
   		selectedFields = new List<FieldWrapper>();
   		
   		Integer i = 0;
    	String query = 'SELECT ';
   		
   		for (FieldWrapper wrapper: allFields)
   		{
   			if (wrapper.selected != null 
   			  && wrapper.selected == true)
   			{
   				if (i != 0)
	    		{
	    			query += ', ';
	    		}
	    		
	    		query += wrapper.name;
   				
   				selectedFields.add(wrapper);
   				i++;
   			}
   		}
   		
   		if (selectedFields.isEmpty())
   		{
   			error('You must select some fields.');
   			return;
   		}
   		
   		Set<Id> ids = new Set<Id>();
    	
    	for (SObject obj : standardController.getSelected())
    	{
    		ids.add(obj.Id);
    	}
    	
    	query += ' FROM ' + recordTypeName + ' WHERE Id IN : ids';
    	listObjects = Database.query(query);
   		
   		getSelectedTable();
   	}
   
   	/**
   	 * Create a preview of the table from the selected fields using a dynamic Visualforce component.
   	 */
	public Component.Apex.PageBlockTable getSelectedTable()
   	{
   		Component.Apex.PageBlockTable table = new Component.Apex.PageBlockTable();
   		table.value=listObjects;
   		table.var='o';
   		
   		if (selectedFields != null)
		{   		
	   		for (FieldWrapper field : selectedFields)
	   		{
	   			Component.Apex.Column col = new Component.Apex.Column();
	            col.expressions.value = '{!o.' + field.name + '}';
	            
	            table.childComponents.add(col);
	   		}
		}
   		
   		return table;
   	}
   	
   	/**
   	 * Submits an API call to Google to find the Google Sheets, adding the results to a list.
   	 */
    private void findGoogleSheets()
    {
        sheetSelectOptions = new List<SelectOption>();
        worksheetSelectOptions = new List<SelectOption>();
        selectedSheetId = null;
        selectedWorksheetId = null;
        
        ffhttp_GoogleSheetsSpreadsheets sheets = createGoogleSheetsSpreadsheets();
        if (sheets == null)
        {   
            return;
        }
        
        ffhttp_GoogleSheetsSpreadsheets.ListRequest request = sheets.listRequest();
        ffhttp_GoogleSheetsModelAbstractObject.SheetsList rawSheetsList = (ffhttp_GoogleSheetsModelAbstractObject.SheetsList)execute(request);
        List<ffhttp_IXmlSerializable> sheetsList = (List<ffhttp_IXmlSerializable>)rawSheetsList.getItems();
        for (ffhttp_IXmlSerializable xml : sheetsList)
        {
            ffhttp_GoogleSheetsModelSheet sheet = (ffhttp_GoogleSheetsModelSheet)xml;
            SelectOption sheetOption = new SelectOption(sheet.getShortId(), sheet.getTitle());
            sheetSelectOptions.add(sheetOption);
        }
    }
    
    /**
     * Submits an API call to Google to find the Google Worksheets for the selected sheet, adding the results to a list.
     */
    public void updateSelectedSheet()
    {
        worksheetSelectOptions = new List<SelectOption>();
        selectedWorksheetId = null;
        
        ffhttp_GoogleSheetsWorksheets sheets = createGoogleSheetsWorksheets(selectedSheetId);
        if (sheets == null)
        {   
            return;
        }
        
        ffhttp_GoogleSheetsWorksheets.ListRequest request = sheets.listRequest();
        ffhttp_GoogleSheetsModelAbstractObject.SheetsList rawSheetsList = (ffhttp_GoogleSheetsModelAbstractObject.SheetsList)execute(request);
        if (rawSheetsList == null)
        {
            return;
        }
        
        List<ffhttp_IXmlSerializable> sheetsList = (List<ffhttp_IXmlSerializable>)rawSheetsList.getItems();
        for (ffhttp_IXmlSerializable xml : sheetsList)
        {
            ffhttp_GoogleSheetsModelWorksheet worksheet = (ffhttp_GoogleSheetsModelWorksheet)xml;
            SelectOption worksheetOption = new SelectOption(worksheet.getShortId(), worksheet.getTitle());
            worksheetSelectOptions.add(worksheetOption);
        }
    }
    
    /**
     * Exports the data in the preview table to the selected sheet and worksheet.
     */
    public void exportData()
    {
    	ffhttp_GoogleSheetsCells cells = createGoogleSheetsCells(selectedSheetId, selectedWorksheetId);
        if (cells == null)
        {
            return;
        }
       
        if (listObjects.isEmpty())
        {
            info('No data to sync.');
            return;
        }
    	
    	String idPrefix = 'https://spreadsheets.google.com/feeds/cells/' + selectedSheetId + '/' + selectedWorksheetId + '/private/full/';
    
        Map<String, Object> hmCellIdToValue = new Map<String, Object>();
        createHeaders(hmCellIdToValue);
        addData(hmCellIdToValue, listObjects);
        
		ffhttp_GoogleSheetsModelBatch queryBatch = new ffhttp_GoogleSheetsModelBatch();  
  
  		Integer cellCount = 0;
        Set<String> cellIds = hmCellIdToValue.keySet();
        for (String cellId : cellIds)
        {
            ffhttp_GoogleSheetsModelCell cell = new ffhttp_GoogleSheetsModelCell();
            cell.setId(idPrefix + cellId);
            
            queryBatch.addCell(ffhttp_GoogleSheetsModelBatch.BATCH_OPERATION_QUERY, cell);
            cellCount++;
            
            if (Math.mod(cellCount, BATCH_SIZE) == 0)
            {
            	if (!queryAndUpdate(cells, queryBatch, hmCellIdToValue))
            	{
            		error('Unsuccessful sync');
            		return;
            	}
            	
            	queryBatch = new ffhttp_GoogleSheetsModelBatch();
            }   
        }
        
        if (Math.mod(cellCount, BATCH_SIZE) > 0 
       	  && !queryAndUpdate(cells, queryBatch, hmCellIdToValue))
    	{
    		error('Unsuccessful sync');
    		return;
    	}
       
       	info('Successful sync: ' + cellCount + ' cells.');
    }
    
    /**
     * Submits an API call to Google to query a set of cells, updating the cells with the results from the preview table.
     */
    private Boolean queryAndUpdate(ffhttp_GoogleSheetsCells cells, ffhttp_GoogleSheetsModelBatch queryBatch,
    							   Map<String, Object> hmCellIdToValue)
    {
    	ffhttp_GoogleSheetsCells.BatchRequest request = cells.batchRequest(queryBatch);
        ffhttp_GoogleSheetsModelBatch responseBatch = (ffhttp_GoogleSheetsModelBatch)execute(request);
        if (responseBatch == null || responseBatch.hasError())
        {
            return false;
        }           
        
        List<ffhttp_GoogleSheetsModelCell> queryCells = responseBatch.getCellsForOperation(ffhttp_GoogleSheetsModelBatch.BATCH_OPERATION_QUERY);
        
        ffhttp_GoogleSheetsModelBatch updateBatch = new ffhttp_GoogleSheetsModelBatch();
        for (ffhttp_GoogleSheetsModelCell cell : queryCells)
        {
            Object value = hmCellIdToValue.get(cell.getShortId());  
            cell.setInputValue(String.valueOf(value));
            
            updateBatch.addCell(ffhttp_GoogleSheetsModelBatch.BATCH_OPERATION_UPDATE, cell);
        }
        
        request = cells.batchRequest(updateBatch);
        responseBatch = (ffhttp_GoogleSheetsModelBatch) execute(request);
        return responseBatch != null && !responseBatch.hasError();
    }
    
    /**
     * Adds the headings to the table.
     */
    private void createHeaders(Map<String, Object> hmCellIdToValue)
    {
    	Integer col = 1;
    	for (FieldWrapper field : selectedFields)
    	{
    		hmCellIdToValue.put('R1C' + col, field.label);
    		col++;
    	}
    }
    
    /**
     * Adds the data to the table.
     */
    private void addData(Map<String, Object> hmCellIdToValue, List<SObject> objects)
    {
    	Integer col = 1;
        Integer row = 2;
        
        for (SObject obj : objects)
        {
        	String objJson = JSON.serialize(obj);
	    	Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(objJson);
	    	
			for (FieldWrapper field : selectedFields)
    		{
    			hmCellIdToValue.put('R' + row + 'C' + col, results.get(field.name));
    		 	col++;	
	    	}
        	
        	col = 1;
            row++;
        }
    }
    
    /**
     * Standard Google Sheets implementation
     */
    private ffhttp_GoogleSheetsSpreadsheets createGoogleSheetsSpreadsheets()
    {
       	ffhttp_GoogleSheets gs = createGoogleSheets();
        return (ffhttp_GoogleSheetsSpreadsheets)gs.spreadsheets();    
    }
    
    private ffhttp_GoogleSheetsWorksheets createGoogleSheetsWorksheets(String spreadsheetId)
    {
        if (stringValueNotSet('Available Spreadsheets', 'Selected Spreadsheet', spreadsheetId))
        {
            return null;
        }
        
        ffhttp_GoogleSheetsModelSheet spreadsheet = new ffhttp_GoogleSheetsModelSheet();
        spreadsheet.setId(spreadsheetId);
        
        ffhttp_GoogleSheets gs = createGoogleSheets();
        ffhttp_GoogleSheetsWorksheets worksheets = gs.worksheets();
        worksheets.setSheet(spreadsheet);
        return worksheets;
    }
    
    private ffhttp_GoogleSheetsCells createGoogleSheetsCells(String spreadsheetId, String worksheetId)
    {
        if (stringValueNotSet('Available Spreadsheets', 'Selected Spreadsheet', spreadsheetId)
          || stringValueNotSet('Available Worksheets', 'Selected Worksheet', worksheetId))
        {
            return null;
        }
        
        ffhttp_GoogleSheetsModelSheet spreadsheet = new ffhttp_GoogleSheetsModelSheet();
        spreadsheet.setId(spreadsheetId);
        
        ffhttp_GoogleSheetsModelWorksheet worksheet = new ffhttp_GoogleSheetsModelWorksheet();
        worksheet.setId(worksheetId);
        
        ffhttp_GoogleSheets gs = createGoogleSheets();
        ffhttp_GoogleSheetsCells cells = gs.cells();
        cells.setSheet(spreadsheet);
        cells.setWorksheet(worksheet);
        return cells;
    }
    
    private ffhttp_GoogleSheets createGoogleSheets()
    {
    	String tokenType = connectorService.connector.tokenType__c;
        String accessToken = connectorService.connector.accessToken__c;
        
    	ffhttp_Client.Credentials credentials = new ffhttp_Client.Credentials(tokenType, accessToken);
        return new ffhttp_GoogleSheets(credentials);
    }
    
    private Object execute(ffhttp_Client.AbstractClientRequest request) 
    {
        Object retval;
        
        try
        {
        	HttpRequest httpRequest = request.buildHttpRequest();
           	retval = request.execute();
        }
        catch (Exception ex)
        {
            error('Error whilst processing request: ' + ex.getMessage());
        } 
        
        return retval;  
    }
    
    private void error(String message) 
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }
    
    private void info(String message) 
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
    }
    
    private Boolean stringValueNotSet(String calloutSection, String name, String value)
    {
        if (String.isEmpty(value))
        {
            error(calloutSection + ': ' + name + ' must be set.');
            return true;
        }
        return false;
    }
    
    /**
     * FieldWrapper
     *
     * Simple inner class to wrap up the details of a field together with whether it is selected.
     */
   	public class FieldWrapper
   	{
   		public Boolean selected { get; set; }
   		public String label { get; set; }
   		public String name { get; set; }
   		
   		public FieldWrapper(String label, String name, boolean selected)
   		{
   			this.label = label;
   			this.name = name;
   			this.selected = selected;
   		}
   	}
}
