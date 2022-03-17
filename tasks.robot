*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    #auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    0.1s
${PDF_RECEIPTS_TEMP_DIRECTORY}=    ${OUTPUT_DIR}${/}receipts
${PNG_SCREENSHOTS_TEMP_DIRECTORY}=    ${OUTPUT_DIR}${/}screenshots

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create temporary directories
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Remove temporary directories

*** Keywords ***
Create temporary directories
    Create Directory    ${PDF_RECEIPTS_TEMP_DIRECTORY}
    Create Directory    ${PNG_SCREENSHOTS_TEMP_DIRECTORY}

Remove temporary directories
    Remove Directory    ${PDF_RECEIPTS_TEMP_DIRECTORY}    True
    Remove Directory    ${PNG_SCREENSHOTS_TEMP_DIRECTORY}    True

Open the robot order website
    ${order_url}=    Get the robot order url from local Vault
    Open Available Browser    ${order_url}

Get orders
    ${csv_url}=    Ask the user to provide the URL of the orders CSV file
    Download    ${csv_url}    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    [Return]    ${table}

Close the annoying modal
    Wait Until Element Is Visible    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview
# Submit the order
#    Click Button    id:order
#    Wait Until Keyword Succeeds
#    ...    3x
#    ...    0.5s
#    ...    Element should be visible
#    ...    id:receipt

Submit the order and check if succeeded
    Click Button    id:order
    Element Should Be Visible    id:receipt
    Element Should Be Visible    id:order-completion

Submit the order
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Submit the order and check if succeeded

Go to order another robot
    Click Button    id:order-another

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    # ${pdf_file_path}=    ${OUTPUT_DIR}${/}receipts
    # ${pdf_file_name}=    Order_no_${order_number}.pdf
    # Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${pdf_file_name}
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}Order_no_${order_number}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}Order_no_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}screenshots${/}Order_no_${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}screenshots${/}Order_no_${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/receipts.zip
    Archive Folder With Zip
    ...    ${PDF_RECEIPTS_TEMP_DIRECTORY}
    ...    ${zip_file_name}

Ask the user to provide the URL of the orders CSV file
    Add heading    User input required!
    Add text    Please provide URL of the orders CSV file
    Add text input    url    label=URL
    ${result}=    Run dialog
    [Return]    ${result.url}

Get the robot order url from local Vault
    ${secret}=    Get Secret    secret_url
    [Return]    ${secret}[robot_order_url]
