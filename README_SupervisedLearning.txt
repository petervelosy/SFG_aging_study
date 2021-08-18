    SFGintro(SUBJECT_ID) - ebben generálhat magának ingereket (emelkedő, ereszkedő, csak háttérzaj)
    SFGIntroTrainingSL(SUBJECT_ID) - feedback-kel nagyon könnyűtől nehezebbig haladó hangok accuracy-ellenőrzéssel (min 75%)
    SFGthresholdBackgroundSL(SUBJECT_ID, GROUP)  - Threshold-mérés (GROUP='Young', 'Elderly', 'ElderlyHI'). A végén a standard deviation-értékeket össze kell vetni (a kiírt referenciaérték alatt kell lennie)
    stimulusGeneratiyonGlueSL(SUBJECT_ID) - Ingerek generálása (csak egyszer szabad futtatni ksz-enként)

    ------------------------------------

    SFGmainSL(SUBJECT_ID, SESSION_ID, false, false, 'yes', 4) - teszt, ez lesz majd EEG-vel (SESSION_ID: 'pretest' vagy 'posttest')
    SFGmainSL(SUBJECT_ID, SESSION_ID, true, false, 'yes', 8) - training feedback-kel (EEG nélkül) (SESSION_ID: 'training1', 'training2', stb.)

    plotStaircase(SUBJECT_ID) - staircase megjelenítése. Blokkonként külön adatsort jelenít meg.