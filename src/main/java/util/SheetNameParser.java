package util;

import lombok.extern.slf4j.Slf4j;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Slf4j
public class SheetNameParser {


    private static final Pattern PATTERN =
            Pattern.compile("^(\\d+_)?([A-Z]{2,5}\\d{2,4})(?:_([A-Z]{2,4}\\d{3,5}))?$");

    public static String[] parse(String sheetName) {
        if (sheetName == null || sheetName.isBlank()) return new String[]{null, null};

        String cleaned = sheetName.trim().toUpperCase();
        Matcher m = PATTERN.matcher(cleaned);

        if (!m.matches()) {
            log.warn("Không parse được tên tab: {}", sheetName);
            return new String[]{null, null};
        }

        return new String[]{ m.group(2), m.group(3) };
    }
}