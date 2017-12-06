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
 * GoogleSheetsTestHarnessController
 * 
 * Controller class for testing all the Google Sheets API calls.
 */
public with sharing class GoogleSheetsTestHarnessController
{
	//Instance variables
	public ConnectorService connectorService;
	public Boolean validConnector { get; set; }
   
   	//Spreadsheet requests
   	public String spreadsheetsGetRequestId { get; set; }
   	
   	//Worksheets requests
   	public String worksheetsDeleteRequestSpreadsheetId { get; set; }
   	public String worksheetsDeleteRequestId { get; set; }
   	   	
   	public String worksheetsGetRequestSpreadsheetId { get; set; }
   	public String worksheetsGetRequestId { get; set; }
   	
   	public String worksheetsInsertRequestSpreadsheetId { get; set; }
   	public String worksheetsInsertRequestTitle { get; set; }
   	public Integer worksheetsInsertRequestColCount { get; set; }
   	public Integer worksheetsInsertRequestRowCount { get; set; }   
   
   	public String worksheetsListRequestSpreadsheetId { get; set; }
   		
   	public String worksheetsUpdateRequestSpreadsheetId { get; set; }
   	public String worksheetsUpdateRequestId { get; set; }
   	public String worksheetsUpdateRequestVersion { get; set; }
   	public String worksheetsUpdateRequestTitle { get; set; }
   	public Integer worksheetsUpdateRequestColCount { get; set; }
   	public Integer worksheetsUpdateRequestRowCount { get; set; }   
   	
   	//Cells Requests
   	public String cellsBatchRequestSpreadsheetId { get; set; }
   	public String cellsBatchRequestWorksheetId { get; set; }
   	
   	public String cellsBatchRequestOperation { get; set; }
   	public String cellsBatchRequestVersion { get; set; }
   	public String cellsBatchRequestCol { get; set; }
   	public String cellsBatchRequestRow { get; set; }
   	public String cellsBatchRequestInputValue { get; set; }
   	
   	public List<CellWrapper> cellsBatchRequestValues { get; set; }
   		
   	public String cellsGetRequestSpreadsheetId { get; set; }
   	public String cellsGetRequestWorksheetId { get; set; }
   	public String cellsGetRequestCellId { get; set; }
   	
   	public String cellsListRequestSpreadsheetId { get; set; }
   	public String cellsListRequestWorksheetId { get; set; }
	public Integer cellsListRequestMinCol { get; set; }
	public Integer cellsListRequestMaxCol { get; set; }
	public Integer cellsListRequestMinRow { get; set; }
	public Integer cellsListRequestMaxRow { get; set; }
	
	public String cellsUpdateRequestSpreadsheetId { get; set; }
   	public String cellsUpdateRequestWorksheetId { get; set; }
   	public String cellsUpdateRequestVersion { get; set; }
   	public Integer cellsUpdateRequestCol { get; set; }
   	public Integer cellsUpdateRequestRow { get; set; }
   	public String cellsUpdateRequestInputValue { get; set; }
   	
    /**
     * Constructors
     */
    public GoogleSheetsTestHarnessController()
    {
        this.connectorService = getConnectorService();
        this.init();
    }
    
    private void init()
   	{
   		cellsBatchRequestValues = new List<CellWrapper>();
   		
        if (connectorService != null)
        {
        	String msg = connectorService.validateConnector();
        	validConnector = String.isEmpty(msg);
        	if (!validConnector)
        	{
        		error(msg);
        	}
        	else
        	{
        		info('Successful authentication. The \'' + connectorService.Connector.Name + '\' connector is being used for authentication.');
        	}
        }
        else
        {
        	error('Google Sheets connector not found.');
        }
   	}
   	
   	/**
     * Gets a valid connector for Google requests.
     *
     * Note: for separation of concerns consider using a selector pattern.
	 * See https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
     */
    public ConnectorService getConnectorService()
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
     * Spreadsheets calls
     */
    public void spreadsheetsGetRequest()
    {
    	ffhttp_GoogleSheetsSpreadsheets sheets = createGoogleSheetsSpreadsheets();
    	if (sheets == null
    	  || stringValueNotSet('Spreadsheets', 'Id', spreadsheetsGetRequestId))
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsSpreadsheets.GetRequest request = sheets.getRequest(spreadsheetsGetRequestId);
    	execute(request);
    }
    
    public void spreadsheetsListRequest()
    {
    	ffhttp_GoogleSheetsSpreadsheets sheets = createGoogleSheetsSpreadsheets();
    	if (sheets == null)
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsSpreadsheets.ListRequest request = sheets.listRequest();
    	execute(request);
    }
    
    private ffhttp_GoogleSheetsSpreadsheets createGoogleSheetsSpreadsheets()
    {
    	if (!checkAuthorized())
    	{
    		return null;
    	}
    	
        ffhttp_GoogleSheets gs = createGoogleSheets();
        return (ffhttp_GoogleSheetsSpreadsheets)gs.spreadsheets();    
    }
    
    /**
     * Worksheets calls
     */
    public void worksheetsDeleteRequest()
    {
    	ffhttp_GoogleSheetsWorksheets sheets = createGoogleSheetsWorksheets(worksheetsDeleteRequestSpreadsheetId);
    	if (sheets == null
    	  || stringValueNotSet('Worksheets', 'Id', worksheetsDeleteRequestId))
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsWorksheets.DeleteRequest request = sheets.deleteRequest(worksheetsDeleteRequestId);
    	execute(request);
    }
    
    public void worksheetsGetRequest()
    {
    	ffhttp_GoogleSheetsWorksheets sheets = createGoogleSheetsWorksheets(worksheetsGetRequestSpreadsheetId);
    	if (sheets == null
    	  || stringValueNotSet('Worksheets', 'Id', worksheetsGetRequestId))
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsWorksheets.GetRequest request = sheets.getRequest(worksheetsGetRequestId);
    	execute(request);
    }
    
    public void worksheetsInsertRequest()
    {
    	ffhttp_GoogleSheetsWorksheets sheets = createGoogleSheetsWorksheets(worksheetsInsertRequestSpreadsheetId);
    	if (sheets == null
    	  || stringValueNotSet('Worksheets', 'Title', worksheetsInsertRequestTitle)
    	  || numberValueNotSet('Worksheets', 'Col Count', worksheetsInsertRequestColCount)
    	  || numberValueNotSet('Worksheets', 'Row Count', worksheetsInsertRequestRowCount))
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsModelWorksheet worksheet = new ffhttp_GoogleSheetsModelWorksheet();
    	worksheet.setTitle(worksheetsInsertRequestTitle);
    	worksheet.setColCount(worksheetsInsertRequestColCount);
    	worksheet.setRowCount(worksheetsInsertRequestRowCount);
    	
    	ffhttp_GoogleSheetsWorksheets.InsertRequest request = sheets.insertRequest(worksheet);
    	execute(request);
    }
    
    public void worksheetsListRequest()
    {
    	ffhttp_GoogleSheetsWorksheets sheets = createGoogleSheetsWorksheets(worksheetsListRequestSpreadsheetId);
    	if (sheets == null)
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsWorksheets.ListRequest request = sheets.listRequest();
    	execute(request);
    }
    
    public void worksheetsUpdateRequest()
    {
    	ffhttp_GoogleSheetsWorksheets sheets = createGoogleSheetsWorksheets(worksheetsUpdateRequestSpreadsheetId);
    	if (sheets == null
    	  || stringValueNotSet('Worksheets', 'Id', worksheetsUpdateRequestId)
    	  || stringValueNotSet('Worksheets', 'Version', worksheetsUpdateRequestVersion))
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsModelWorksheet worksheet = new ffhttp_GoogleSheetsModelWorksheet();
    	worksheet.setId(worksheetsUpdateRequestId);
    	worksheet.setVersion(worksheetsUpdateRequestVersion);
    	worksheet.setTitle(worksheetsUpdateRequestTitle);
    	worksheet.setColCount(worksheetsUpdateRequestColCount);
    	worksheet.setRowCount(worksheetsUpdateRequestRowCount);
    	
    	ffhttp_GoogleSheetsWorksheets.UpdateRequest request = sheets.updateRequest(worksheet);
    	execute(request);
    }
    
    private ffhttp_GoogleSheetsWorksheets createGoogleSheetsWorksheets(String spreadsheetId)
    {
    	if (!checkAuthorized())
    	{
    		return null;
    	}
    	
    	if (stringValueNotSet('Worksheets', 'Spreadsheet Id', spreadsheetId))
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
    
    /**
     * Cells calls
     */
    public void cellsBatchRequest()
    {
    	ffhttp_GoogleSheetsCells cells = createGoogleSheetsCells(cellsBatchRequestSpreadsheetId, cellsBatchRequestWorksheetId);
    	if (cells == null)
    	{	
    		return;
    	}
    	
    	if (cellsBatchRequestValues.isEmpty())
    	{
    		error('You must add at least one cell to update.');
    		return;
    	}
    	
    	ffhttp_GoogleSheetsModelBatch batch = new ffhttp_GoogleSheetsModelBatch();
    	
    	for (CellWrapper cw : cellsBatchRequestValues)
    	{
    		cw.cell.setId('https://spreadsheets.google.com/feeds/cells/' + cellsBatchRequestSpreadsheetId + '/' + cellsBatchRequestWorksheetId + '/private/full/R' + cw.cell.getRow() + 'C' + cw.cell.getCol());
    		
    		if (cw.operation.equals('update'))
    		{
    			cw.cell.addUrlLink('edit', 'application/atom+xml', 'https://spreadsheets.google.com/feeds/cells/' + cellsBatchRequestSpreadsheetId + '/' + cellsBatchRequestWorksheetId + '/private/full/R' + cw.cell.getRow() + 'C' + cw.cell.getCol() + '/' + cw.cell.getVersion());
    			cw.cell.setInputValue(cw.inputValue);
    		}
    		
    		batch.addCell(cw.operation, cw.cell);
    	}
    	
    	ffhttp_GoogleSheetsCells.BatchRequest request = cells.batchRequest(batch);
    	ffhttp_GoogleSheetsModelBatch responseBatch = (ffhttp_GoogleSheetsModelBatch)execute(request);
    	processBatchResponse(responseBatch);
   }
    
   private void processBatchResponse(ffhttp_GoogleSheetsModelBatch responseBatch)
   {
   		if (responseBatch == null)
   		{
   			return;
   		}
   		
   		if (responseBatch.hasError())
    	{
    		Map<String, List<ffhttp_GoogleSheetsModelCell>> hmErrorToCellList = responseBatch.getErrorToCellList();
    		Set<String> errors = hmErrorToCellList.keySet();
    		for (String error : errors)
    		{
    			List<ffhttp_GoogleSheetsModelCell> cellList = (List<ffhttp_GoogleSheetsModelCell>)hmErrorToCellList.get(error);
    			error('Error found whilst processing batch: ' + error + ' Count: ' + cellList.size());
    		}
    	}
   		
    	cellsBatchRequestValues.clear();
    
    	List<ffhttp_GoogleSheetsModelCell> queryCells = responseBatch.getCellsForOperation('query');
    	processCellBatch(queryCells);
    	
    	List<ffhttp_GoogleSheetsModelCell> updateCells = responseBatch.getCellsForOperation('update');
    	processCellBatch(updateCells);
    }
    
    private void processCellBatch(List<ffhttp_IXmlSerializable> cells)
    {
    	if (cells != null)
    	{
	    	for (ffhttp_IXmlSerializable cell : cells)
	    	{
	    		cellsBatchRequestValues.add(new CellWrapper('update', (ffhttp_GoogleSheetsModelCell)cell));
	    	}
    	}
    }
     
    public void cellsBatchRequestAddCells()
    {
    	if (stringValueNotSet('Cells', 'Operation', cellsBatchRequestOperation)
    	  || stringValueNotSet('Cells', 'Batch Row', cellsBatchRequestRow)
    	  || stringValueNotSet('Cells', 'Batch Col', cellsBatchRequestCol))
    	{	
    		return;
    	}
    	
    	try
    	{
	    	List<Integer> splitCellsBatchRequestRowInt = new List<Integer>();
	    	List<Integer> splitCellsBatchRequestColInt = new List<Integer>();
	    	
	    	if (cellsBatchRequestRow.contains('-'))
	    	{
	    		String[] splitCellsBatchRequestRow = cellsBatchRequestRow.split('-', 0);
	    		
	    		Integer min = Integer.valueOf(splitCellsBatchRequestRow[0]);
	    		Integer max = Integer.valueOf(splitCellsBatchRequestRow[1]);
	    		
	    		while (min <= max)
	    		{
	    			splitCellsBatchRequestRowInt.add(min);
	    			min++;
	    		}
	    	}
	    	else
	    	{
	    		splitCellsBatchRequestRowInt.add(Integer.valueOf(cellsBatchRequestRow));
	    	}
	    	
	    	if (cellsBatchRequestCol.contains('-'))
	    	{
	    		String[] splitCellsBatchRequestCol = cellsBatchRequestCol.split('-', 0);
	    		
	    		Integer min = Integer.valueOf(splitCellsBatchRequestCol[0]);
	    		Integer max = Integer.valueOf(splitCellsBatchRequestCol[1]);
	    		
	    		while (min <= max)
	    		{
	    			splitCellsBatchRequestColInt.add(min);
	    			min++;
	    		}
	    	}
	    	else
	    	{
	    		splitCellsBatchRequestColInt.add(Integer.valueOf(cellsBatchRequestCol));
	    	}
	    	
	    	for (Integer col : splitCellsBatchRequestColInt)
	    	{
	    		for (Integer row : splitCellsBatchRequestRowInt)
	    		{
	    			ffhttp_GoogleSheetsModelCell cell = new ffhttp_GoogleSheetsModelCell();
			    	cell.setRow(row);
			    	cell.setCol(col);
			    	cell.setInputValue(cellsBatchRequestInputValue);
			    	cell.setVersion(cellsBatchRequestVersion);
			    	
			    	cellsBatchRequestValues.add(new CellWrapper(cellsBatchRequestOperation, cell));
	    		}
	    	}
    	}
    	catch (Exception ex)
    	{
    		error('Invalid cell input.');
    	}
    }
    
    public void cellsBatchRequestResetCells()
    {
    	cellsBatchRequestValues.clear();
    }
     
    public void cellsGetRequest()
    {
    	ffhttp_GoogleSheetsCells cells = createGoogleSheetsCells(cellsGetRequestSpreadsheetId, cellsGetRequestWorksheetId);
    	if (cells == null
    	  || stringValueNotSet('Cells', 'Cell Id', cellsGetRequestCellId))
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsCells.GetRequest request = cells.getRequest(cellsGetRequestCellId);
    	execute(request);
    } 
    
    public void cellsListRequest()
    {
    	ffhttp_GoogleSheetsCells cells = createGoogleSheetsCells(cellsListRequestSpreadsheetId, cellsListRequestWorksheetId);
    	if (cells == null)
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsCells.ListRequest request = cells.listRequest();
    	
    	if (cellsListRequestMinCol != null && cellsListRequestMinCol > 0)
    	{
    		request.setMinCol(cellsListRequestMinCol);
    	}
    	
    	if (cellsListRequestMaxCol != null && cellsListRequestMaxCol > 0)
    	{
    		request.setMaxCol(cellsListRequestMaxCol);
    	}
    	
    	if (cellsListRequestMinRow != null && cellsListRequestMinRow > 0)
    	{
    		request.setMinRow(cellsListRequestMinRow);
    	}
    	
    	if (cellsListRequestMaxRow != null && cellsListRequestMaxRow > 0)
    	{
    		request.setMaxRow(cellsListRequestMaxRow);
    	}
    	
    	ffhttp_GoogleSheetsModelAbstractObject.SheetsList responseBatch = (ffhttp_GoogleSheetsModelAbstractObject.SheetsList)execute(request);
    	if (responseBatch != null)
    	{
    		cellsBatchRequestValues.clear();
    		processCellBatch(responseBatch.getItems());
    	}
    } 
    
    public void cellsUpdateRequest()
    {
    	ffhttp_GoogleSheetsCells cells = createGoogleSheetsCells(cellsUpdateRequestSpreadsheetId, cellsUpdateRequestWorksheetId);
    	if (cells == null
    	  || stringValueNotSet('Cells', 'Version', cellsUpdateRequestVersion)
    	  || numberValueNotSet('Cells', 'Col', cellsUpdateRequestCol)
    	  || numberValueNotSet('Cells', 'Row', cellsUpdateRequestRow)
    	  || stringValueNotSet('Cells', 'Input Value', cellsUpdateRequestInputValue))
    	{	
    		return;
    	}
    	
    	ffhttp_GoogleSheetsModelCell cell = new ffhttp_GoogleSheetsModelCell();
    	cell.setId('https://spreadsheets.google.com/feeds/cells/' + cellsBatchRequestSpreadsheetId + '/' + cellsBatchRequestWorksheetId + '/private/full/R' + cellsUpdateRequestRow + 'C' + cellsUpdateRequestCol);
    	cell.setCol(cellsUpdateRequestCol);
    	cell.setRow(cellsUpdateRequestRow);
    	cell.setInputValue(cellsUpdateRequestInputValue);
    	cell.setVersion(cellsUpdateRequestVersion);
    	
    	ffhttp_GoogleSheetsCells.UpdateRequest request = cells.updateRequest(cell);
    	execute(request);
    } 
    
    public ffhttp_GoogleSheetsCells createGoogleSheetsCells(String spreadsheetId, String worksheetId)
    {
    	if (!checkAuthorized())
    	{
    		return null;
    	}
    	
    	if (stringValueNotSet('Cells', 'Spreadsheet Id', spreadsheetId)
    	  || stringValueNotSet('Cells', 'Worksheet Id', worksheetId))
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
    	String tokenType = connectorService.connector.TokenType__c;
    	String accessToken = connectorService.connector.AccessToken__c;
    	
    	ffhttp_Client.ICredentials credentials = new ffhttp_Client.AccessTokenCredentials(tokenType, accessToken);
        return new ffhttp_GoogleSheets(credentials);
    }
    
    /**
     * Helper methods
     */
    private void error(String message) 
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }
    
    private void info(String message) 
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
    }
    
    private Object execute(ffhttp_Client.AbstractClientRequest request) 
    {
    	Object retval;
    	
        try
        {
            HttpRequest httpRequest = request.buildHttpRequest();
            
            String endpoint = httpRequest.getEndpoint();
            String method = httpRequest.getMethod();
            String requestBody = httpRequest.getBody();
            
            info('Request: Endpoint: ' + endpoint);
            info('Request: Method: ' + method);
            info('Request: Body: ' + requestBody);
        
            HttpResponse response = request.executeUnparsed();
            String status = response.getStatus();
            String responseBody = response.getBody();
            info('Response: Status: ' + status);
            info('Response: Body: ' + responseBody);
            
            retval = request.parse(response);
        }
        catch (Exception ex)
        {
        	error('Error whilst processing request: ' + ex.getMessage());
        }  
        
        return retval;  
    }
    
    private Boolean checkAuthorized()
	{
		if (connectorService == null)
		{
			return false;
		}
		
		String validConnector = connectorService.validateConnector();
		if (!String.isEmpty(validConnector))
		{
			error(validConnector);
		}
		
		return String.isEmpty(validConnector);
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
	
	private Boolean numberValueNotSet(String calloutSection, String name, Integer value)
	{
		if (value == null || value <= 0)
		{
			error(calloutSection + ': ' + name + ' must be set.');
			return true;
		}
		return false;
	}
	
	/**
	 * List Methods
	 */
	public List<SelectOption> getCellBatchOperationTypes()
	{
    	List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(ffhttp_GoogleSheetsModelBatch.BATCH_OPERATION_QUERY, 'Query'));
        options.add(new SelectOption(ffhttp_GoogleSheetsModelBatch.BATCH_OPERATION_UPDATE, 'Update'));
        return options;
    }
    
    /**
     * CellWrapper
     */
    public class CellWrapper
    {
    	public String operation { get; set; }
    	public Integer col { get; set; }
    	public Integer row  { get; set; }
    	public String inputValue { get; set; }
    	public String version { get; set; }
    	public Boolean isQuery { get; set; }
    	
    	public ffhttp_GoogleSheetsModelCell cell;
    	
    	public CellWrapper(String operation, ffhttp_GoogleSheetsModelCell cell)
    	{
    		this.isQuery = ffhttp_GoogleSheetsModelBatch.BATCH_OPERATION_QUERY.equals(operation);
    		this.operation = operation;
    		this.cell = cell;
    		this.col = cell.getCol();
    		this.row = cell.getRow();
    		this.inputValue = cell.getInputValue();
    		this.version = cell.findVersion();
    	}
    }
}
