    SFGintro(SUBJECT_ID) - ebben generálhat magának ingereket (emelkedő, ereszkedő, csak háttérzaj)
    SFGIntroTrainingSL(SUBJECT_ID, true) - feedback-kel nagyon könnyűtől nehezebbig haladó hangok accuracy-ellenőrzéssel (min 75%)
    SFGthresholdBackgroundSL(SUBJECT_ID, GROUP)  - Threshold-mérés (GROUP='Young', 'Elderly', 'ElderlyHI'). A végén a standard deviation-értékeket össze kell vetni (a kiírt referenciaérték alatt kell lennie)
    stimulusGenerationGlueSL(SUBJECT_ID) - Ingerek generálása (csak egyszer szabad futtatni ksz-enként)

    ------------------------------------

    SFGmainSL(SUBJECT_ID, false, true, 'no', 4) - teszt, ez lesz majd EEG-vel
    SFGmainSL(SUBJECT_ID, true, true, 'no', 8) - training feedback-kel (EEG nélkül)

    plotStaircase(SUBJECT_ID) - staircase megjelenítése. Blokkonkélnt külön adatsort jelenít meg.