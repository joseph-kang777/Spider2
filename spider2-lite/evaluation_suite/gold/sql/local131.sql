SELECT
    style.StyleID,
    style.StyleName,
    SUM(CASE WHEN preference.PreferenceSeq = 1 THEN 1 ELSE 0 END)
        AS FirstPreferenceCount,
    SUM(CASE WHEN preference.PreferenceSeq = 2 THEN 1 ELSE 0 END)
        AS SecondPreferenceCount,
    SUM(CASE WHEN preference.PreferenceSeq = 3 THEN 1 ELSE 0 END)
        AS ThirdPreferenceCount
FROM Musical_Styles AS style
LEFT JOIN Musical_Preferences AS preference
  ON style.StyleID = preference.StyleID
GROUP BY style.StyleID, style.StyleName
ORDER BY
    FirstPreferenceCount DESC,
    SecondPreferenceCount DESC,
    ThirdPreferenceCount DESC,
    style.StyleID;
