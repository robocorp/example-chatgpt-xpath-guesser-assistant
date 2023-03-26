*** Settings ***
Documentation       GPT HTML locator Guesser
Library    RPA.Browser.Playwright
Library    RPA.FileSystem
Library    RPA.OpenAI
Library    RPA.Robocorp.Vault
Library    RPA.Assistant
Library    RPA.JSON
Library    RPA.Desktop
Library    String
Suite Setup   Auth to OpenAI

*** Variables ***
${prompt}    Create the most reliable possible xpath locators for all of the web elements in the html data. Prefer short and simple one's, but if the "id" or "name" value seems random and might be a dynamic value, prefer some other approach. Write the results into a simple json file without nesting or any additional comments or characters. Give the locators good names based on programming best practices. Html: \n
${prompt_retry}    Following locators didn't work, try again with another strategy. Update the new locators to the json response without any additional info or extra characters. Keep the json non nested and simple.
&{xpath}       Buttons=//button    Inputs=//input    Buttons & Inputs=//input | //button
${correct_count}    ${0}
${locator_total_count}    ${0}
${commented_result}

*** Tasks ***
Minimal task
    Display Main Menu
    ${result}=    RPA.Assistant.Run Dialog
    ...    title=Robocorp Assistant
    ...    on_top=False
    ...    height=800
    ...    width=900
    ...    timeout=720
    ...    location=Center

*** Keywords ***
Auth to OpenAI
    # You can also authenticate to OpenAI without using the Robocorp Vault,
    # by following keyword but it is bad for security.
    # Authorize To Openai   api_key=<your_api_key>
    ${secrets}    Get Secret   OpenAI
    Authorize To Openai    api_key=${secrets}[key]

Display Main Menu
    # Let's clear the conversation history in the main page.
    ${conversation}    Set variable   None

    Set Suite Variable    ${conversation}
    ${incorrect_existed}    Set Variable   no
    Set Suite Variable    ${incorrect_existed}
    Clear Dialog

    # Add elements to the Assistant dialog.
    Add Image    ${CURDIR}${/}logo.png   width=40   height=40
    Add Heading    GPT - HTML selector Guesser
    Add Text Input    input_url    Url to search from
    Add Drop-Down     locators    Buttons,Inputs,Buttons & Inputs    label=Selector type
    Add Drop-Down     model    gpt-3.5-turbo,gpt-4    label=Select the GPT model
    Add Text Input    element_limit    Number of elements searched. Adjust if token limit is reached.    default=100
    Add Text Input    sleep_time     Seconds to wait for user login or other actions.    default=0
    Add Next Ui Button    Get locators    Window Locator Results
    Add Submit Buttons    buttons=Close    default=Close

Back To Main Menu
    [Arguments]   ${form}
    Run Keyword And Ignore Error    Close Browser
    Display Main Menu
    Refresh Dialog

Window Locator Results
    [Arguments]   ${form}
    ${element_limit}    Set Variable    ${form}[element_limit]
    ${model}    Set Variable   ${form}[model]
    Set Suite Variable    ${model}
    Clear Dialog
    Add Heading    Locator Results   size=Medium
    ${element_count}   Find the Elements    ${form}   ${element_limit}
    IF    ${element_count} > ${0}
        ${response_from_GPT}  Create first locators
        ${commented_result}  ${validated_result}   Validate results    ${response_from_GPT}
        Add Text    ${commented_result}
    ELSE
        ${validated_result}  Set Variable    No elements found from the website: ${form}[locators]
    END
    Add Text    ${validated_result}   size=Large
    IF    '${incorrect_existed}' == 'yep'
        Add Next Ui Button    Ask for another strategy for the incorrect ones     Retry Window
    ELSE
        Close Browser
    END
    Add Button    Copy to Clipboard    Copy to Clipboard   ${commented_result}
    Add Next Ui Button    Back    Back To Main Menu
    Refresh Dialog

Find the Elements
    [Arguments]    ${form}   ${element_limit}
    Set Browser Timeout    30
    ${counter}   Set Variable   ${0}
    Open Browser    url=${form}[input_url]
    Sleep   ${form}[sleep_time]
    ${elements}   Get Elements    ${xpath}[${form}[locators]]
    ${element_count}    Get Element Count    ${xpath}[${form}[locators]]
    IF    ${element_count} > ${0}
        Create File    output/element_htmls.txt    overwrite=True
        FOR    ${element}    IN    @{elements}
            ${entities}    Get Elements    ${element}
            FOR    ${entity}    IN    @{entities}
                IF  ${counter} < ${element_limit}
                    ${html}   Get Property   ${entity}    outerHTML
                    RPA.Browser.Playwright.Highlight Elements    ${entity}    width=5px   style=solid   color=red
                    Append To File    output/element_htmls.txt    ${html}
                    ${counter}   Evaluate    ${counter}+1
                END
            END
            Append To File    output/element_htmls.txt    \n
            Exit For Loop If    ${counter} == ${element_limit}
        END
    END
    [Return]   ${element_count}

Create first locators
    ${html}    Read File    output/element_htmls.txt
    Log To Console    \n\n Waiting for OpenAI \n
    ${incorrect_existed}   Set Variable   no
    TRY
        ${response}    Chat Completion to get XPaths   ${prompt}   ${html}
        ${response}    Replace String   ${response}    \n\n    ${EMPTY}
        Create File    output/locators.json    ${response}    overwrite=True
    EXCEPT
        Error happened    ChatGPT gave an error.
    END
    [Return]    ${response}

Chat Completion to get XPaths
    [Arguments]    ${prompt}   ${values_to_gpt}
    Log To Console    \n${prompt} \n ${values_to_gpt}
    ${response}    @{conversation}    Chat Completion Create
    ...    user_content=${prompt} ${values_to_gpt}
    ...    conversation=${conversation}
    ...    model=${model}
    Set Suite Variable    ${conversation}
    [Return]   ${response}

Validate results
    [Arguments]   ${response_from_GPT}
    # For demo purposes page reload on rpachallenge.com site to see that dynamic IDs doesn't work.
    ${url}   Get Url
    Run Keyword If    '${url}' == 'https://rpachallenge.com/'
    ...    Reload
    TRY
        &{json}    Convert String to JSON    ${response_from_GPT}
    EXCEPT
        Error happened    ChatGPT gave wrongly formatted response.
    END
    ${incorrect_locators}   Set Variable    ${EMPTY}
    ${commented_result}   Read File    output/locators.json
    FOR    ${x}    IN    @{json}
        ${xpath}   Get value from JSON    ${json}    $.[${x}]
        ${elements_found}   Get Element Count    ${xpath}
        IF    ${elements_found} > 0
            ${correct_count}    Evaluate   ${correct_count}+1
        ELSE
            ${incorrect_locators}    Set Variable    ${incorrect_locators} \n${xpath}
            ${incorrect_existed}   Set Variable   yep
            Set Suite Variable    ${incorrect_existed}
            ${commented_result}   Replace String    ${commented_result}    ${xpath}     ${xpath} \[NOT_FOUND]
        END
        ${locator_total_count}   Evaluate    ${locator_total_count}+1
    END
    Set Suite Variable   ${incorrect_locators}
    ${validated_result}   Set Variable   Locators matching the elements on the site: ${correct_count}/${locator_total_count}
    [Return]    ${commented_result}   ${validated_result}

Retry Window
    [Arguments]    ${form}
    Clear Dialog
    Add Heading    Locator Results   size=Medium
    ${response_from_GPT}    Chat Completion to get XPaths    ${prompt_retry}    ${incorrect_locators}
    Create File    output/locators.json    ${response_from_GPT}    overwrite=True
    ${commented_result}  ${validated_result}   Validate results    ${response_from_GPT}
    Add Text    ${commented_result}
    Add Text    ${validated_result}   size=Large
    Add Button    Copy to Clipboard    Copy to Clipboard   ${response_from_GPT}
    Add Next Ui Button    Back    Back To Main Menu
    Refresh Dialog
    Close Browser

Copy to Clipboard
    [Arguments]   ${response_from_GPT}
    Set Clipboard Value    ${response_from_GPT}

Error happened
    [Arguments]    ${response}
    Clear Dialog
    Add Heading    Error   size=Medium
    Add Text    ${response}
    Add Next Ui Button    Back    Back To Main Menu
    Refresh Dialog
    Close Browser
