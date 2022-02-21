*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${False}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           XML

*** Variables ***
${web_URL}        https://robotsparebinindustries.com/#/robot-order
${Global_Timeout_XL}    120 sec
${Global_Timeout_L}    60 sec
${Global_Timeout_M}    30 sec
${Global_Timeout_S}    10 sec
${Global_Timeout_XS}    5 sec
${Global_Timeout_XS}    2.5 sec
${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    0.5s
${output_folder_path}    ${CURDIR}/output/
${input_folder_path}    ${CURDIR}/input/
${csv_Path}       ${input_folder_path}orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Run Keyword And Continue On Failure    Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    close the browser

*** Keywords ***
Open the robot order website
    Open Available Browser    ${web_URL}
    Maximize Browser Window

*** Keywords ***
Close the annoying modal
    Click Element If Visible    //button[@class='btn btn-dark' and contains(text(), "OK")]

*** Keywords ***
Get orders
    ${orders}=    Read table from CSV    ${csv_Path}
    [Return]    ${orders}

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview
    Page Should Contain Element    id:robot-preview-image

*** Keywords ***
Submit the order
    FOR    ${counter}    IN RANGE    1    10
        ${res}    Is Element Visible    id:order
        ${res1}    Is Element Visible    id:order-another
        IF    ${res1}
            Exit For Loop
        ELSE
            IF    ${res}
                Submit the order with Retry
            END
        END
    END

Submit the order with Retry
    Wait And Click Button    id:order

*** Keywords ***
Go to order another robot
    Click Button When Visible    id:order-another

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_Number}
    ${file}=    Set Variable    ${output_folder_path}Reciepts/Reciept_${order_Number}.pdf
    Wait Until Element Is Visible    id:receipt    ${Global_Timeout_XL}
    ${receipt_html} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${file}
    [Return]    ${file}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_Number}
    ${file}=    Set Variable    ${output_folder_path}Screenshots/sales_preview_${order_Number}.png
    Screenshot    id:robot-preview-image    ${file}
    [Return]    ${file}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}:align=center
    Add Files To Pdf    ${files}    ${pdf}    append:True

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${output_folder_path}Reciepts/    ${output_folder_path}receipts.ZIP

close the browser
    Close Browser
