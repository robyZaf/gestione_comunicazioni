*** Settings ***
Resource    ../common/common.robot
Library     Collections
Library     String
#Library    RPA.Browser.Selenium    auto_close=${FALSE}


*** Variables ***
${activity_number_in_page}                                  300
@{MANAGED_CATEGORY}                                         cambio mail postalizzazione
...                                                         cambio frequenza pagamento
...                                                         cambio indirizzo intestatario fattura
...                                                         cambio modalita pagamento
...                                                         rid ko

${COMMON_OPTIONAL_FIELD_FORNITURA}                          fornitura
@{MANDATORY_FIELD_CAMBIO_MAIL_POSTALIZZAZIONE}              email
@{MANDATORY_FIELD_CAMBIO_FREQUENZA_PAGAMENTO}               frequenza
@{MANDATORY_FIELD_CAMBIO_INDIRIZZO_INTESTATARIO_FATTURA}    email
@{MANDATORY_FIELD_CAMBIO_MODALITA_PAGAMENTO}                email
&{DICTIONARY}                                               cambio mail postalizzazione=@{MANDATORY_FIELD_CAMBIO_MAIL_POSTALIZZAZIONE}
...                                                         cambio frequenza pagamento=@{MANDATORY_FIELD_CAMBIO_FREQUENZA_PAGAMENTO}
...                                                         cambio indirizzo intestatario fattura=@{MANDATORY_FIELD_CAMBIO_INDIRIZZO_INTESTATARIO_FATTURA}
...                                                         cambio modalita pagamento=@{MANDATORY_FIELD_CAMBIO_MODALITA_PAGAMENTO}


*** Tasks ***
Gestione Comunicazioni
    Access enErp software
    Open Attivita Assegnato a Operatore
    Put all comunicazioni inside one page
    Iterate over comunicazioni and manage


*** Keywords ***
Access enErp software
    ${enerp_ip}    ${user}    ${password}    Get Secret Enerp
    Open enErp    ${enerp_ip}
    Login enErp    ${user}    ${password}

Open Attivita Assegnato a Operatore
    Click Element When Visible    name:CRM
    Click Element When Visible    xpath=//*[@id="menu"]/div[3]/ul/li[3]/a
    Click Element When Visible    xpath=//*[@id="id_75"]/ul/li[2]/a

Put all comunicazioni inside one page
    Wait Until Element Is Visible    //*[@id="com_pagina_ATTOP"]
    Input Text    //*[@id="com_pagina_ATTOP"]    ${activity_number_in_page}
    Click Button    //*[@id="listaAziende2"]/tfoot/tr/td/input[7]
    Wait Until Element Is Visible    //*[@id="listaAziende2"]

Iterate over comunicazioni and manage
    # iterate over comunicazioni
    FOR    ${index}    IN RANGE    1    ${activity_number_in_page}
        ${exists_another_comunicazione}    Check if exists another comunicazione    ${index}
        IF    ${exists_another_comunicazione}
            Log    Activity number ${index}

            ${categoria}    Retrieve categoria from comunicazione    ${index}
            Log    Categoria: ${categoria}
            #Log To Console    id: ${index} Categoria: ${categoria}

            ${categoria_is_managed}    Check if categoria is managed    ${categoria}
            IF    ${categoria_is_managed}
                Log    Categoria: ${categoria}

                ${cliente}    ${p_iva}    ${cf}    ${oggetto}    Retrieve information from comunicazione
                ...    ${index}
                Log    Nome cliente: ${cliente} P. iva: ${p_iva} CF: ${cf} Oggetto: ${oggetto}
                ############
                #    Manage comunicazione    ${categoria}
                #    1. check sulle informazioni obbligatorie in base alla categoria
                #    2. se tutte le informazioni sono presenti esegui altrimenti log e continue
                #    3. mapping tra categoria e funzione da eseguire (la funzione si controlla le info?)
                #    4. se tutto è andato correttamente chiudere segnalazione
                #
                ############
                ${comunicazione_is_managed_correctly}    Manage comunicazione    ${categoria}
                IF    ${comunicazione_is_managed_correctly}
                    # chiudi segnalazione
                    # vedere se bisogna ricaricare pagina o fare altro
                    Log    ok
                ELSE
                    CONTINUE
                END
            ELSE
                CONTINUE
            END

        ELSE
            BREAK
        END
    END

Check if exists another comunicazione
    [Arguments]    ${index}
    ${xpath_comunicazione_to_check}    Set Variable
    ...    /html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index}]
    ${exists}    RPA.Browser.Selenium.Is Element Visible    xpath=${xpath_comunicazione_to_check}
    RETURN    ${exists}

Retrieve categoria from comunicazione
    [Arguments]    ${index}
    ${categoria}    RPA.Browser.Selenium.Get Text
    ...    xpath=/html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index}]/td[7]
    ${categoria_lower}    Convert To Lower Case    ${categoria}
    RETURN    ${categoria_lower}

Check if categoria is managed
    [Arguments]    ${categoria}
    TRY
        List Should Contain Value    ${MANAGED_CATEGORY}    ${categoria}
        RETURN    True
    EXCEPT    .*does not contain value.*    type=regexp
        Log    Categoria: ${categoria} is not managed
        RETURN    False
        #Log To Console    Categoria: ${categoria} is not managed
    END

Retrieve information from comunicazione
    [Arguments]    ${index}
    # open riferimenti (protocollo richiesta)
    Click Link    //*[@id="listaAziende2"]/tbody/tr[${index}]/td[8]/div/a
    # move on new page opened after click
    Switch Window    new
    ${cliente}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[4]/td[2]
    ${p_iva}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[5]/td[2]
    ${cf}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[6]/td[2]
    ${oggetto}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[8]/td[2]
    # close protocollo window
    Click Button    //*[@id="btn_close"]
    Switch Window    main
    RETURN    ${cliente}    ${p_iva}    ${cf}    ${oggetto}

Manage comunicazione
    [Arguments]    ${categoria}
    # return true o false se la gestione è andata a buon fine o meno
    IF    ${categoria} == cambio mail postalizzazione
        Cambio mail postalizzazione
    ELSE IF    ${categoria} == cambio frequenza pagamento
        Cambio frequenza pagamento
    ELSE IF    ${categoria} == cambio indirizzo intestatario fattura
        Cambio indirizzo intestatario fattura
    ELSE IF    ${categoria} == cambio modalita pagamento
        Cambio modalita pagamento
    END

Cambio mail postalizzazione
    #[Arguments]    ${oggetto}
    #TODO

Cambio frequenza pagamento
    #TODO

Cambio indirizzo intestatario fattura
    #TODO

Cambio modalita pagamento
    #TODO
