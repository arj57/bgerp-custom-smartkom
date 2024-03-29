package org.bgerp.plugin.custom.smartkom.imports;

class InnChecker {
    static boolean isInnValid(String inn) {
//      Для проверки ИНН используются одна или две контрольные цифры в конце номера.
//      Алгоритм проверки ИНН: https://www.egrul.ru/test_inn.html  http://www.kholenkov.ru/data-validation/inn/

        if (inn == null)
            return false;
        int[] weightFactor_10 = new int[] { 2, 4, 10, 3, 5, 9, 4, 6, 8 }; // for 10-digit INN
        int[] weightFactor_11 = new int[] { 7, 2, 4, 10, 3, 5, 9, 4, 6, 8 }; // for 12-digit INN (1-st check)
        int[] weightFactor_12 = new int[] { 3, 7, 2, 4, 10, 3, 5, 9, 4, 6, 8 }; // for 12-digit INN (2-nd check)

        switch (inn.length()) {
        case 10:
            return (char) ((int) '0' + weightedSum(inn, weightFactor_10) % 11 % 10) == inn.charAt(9);
        case 12:
            return ((char) ((int) '0' + weightedSum(inn, weightFactor_11) % 11 % 10) == inn.charAt(10))
                    && ((char) ((int) '0' + weightedSum(inn, weightFactor_12) % 11 % 10) == inn.charAt(11));
        }
        return false;
    }

    private static int weightedSum(String s, int[] weights) {
        int len = s.length();
        if (len > weights.length)
            len = weights.length;
        int summ = 0;
        for (int i = 0; i < len; i++) {
            if (!Character.isDigit(s.charAt(i)))
                return -255;
            summ += weights[i] * ((int) s.charAt(i) - (int) '0');
        }
        return summ;
    }
}
