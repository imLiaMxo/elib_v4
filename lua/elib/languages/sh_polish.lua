// Made by Eve Haddox & imLiaMxo

Elib.Lang.Register("pl", "Polski", {

    ////////////////////////////
    // Generic actions & labels
    ////////////////////////////
    ["elib.save"]            = "Zapisz",
    ["elib.save_changes"]    = "Zapisz zmiany",
    ["elib.cancel"]          = "Anuluj",
    ["elib.confirm"]         = "Potwierdź",
    ["elib.close"]           = "Zamknij",
    ["elib.reset"]           = "Resetuj",
    ["elib.revert"]          = "Cofnij",
    ["elib.default"]         = "Domyślne",
    ["elib.apply"]           = "Zastosuj",
    ["elib.delete"]          = "Usuń",
    ["elib.edit"]            = "Edytuj",
    ["elib.back"]            = "Wstecz",
    ["elib.next"]            = "Dalej",
    ["elib.search"]          = "Szukaj",
    ["elib.loading"]         = "Ładowanie...",
    ["elib.disabled"]        = "Wyłączone",
    ["elib.yes"]             = "Tak",
    ["elib.no"]              = "Nie",
    ["elib.ok"]              = "OK",

    ////////////////////////////
    // Table / List element
    ////////////////////////////
    ["elib.table.add"]         = "Dodaj",
    ["elib.table.placeholder"] = "Nowy wpis...",

    ////////////////////////////
    // Frame
    ////////////////////////////
    ["elib.frame.default_title"] = "Okno Elib",

    ////////////////////////////
    // Config menu
    ////////////////////////////
    ["elib.config.title"]          = "Konfiguracja Elib",
    ["elib.config.general"]        = "Ogólne",
    ["elib.config.colors"]         = "Kolory",
    ["elib.config.network"]        = "Sieć",
    ["elib.config.theme"]          = "Motyw",
    ["elib.config.language"]       = "Język",
    ["elib.config.addons"]         = "Dodatki",
    ["elib.config.empty"]          = "Ten dodatek nie ma żadnych ustawień.",

    ["elib.config.subtitle.server"] = "Serwer (tylko administratorzy)",
    ["elib.config.subtitle.client"] = "Klient",

    ////////////////////////////
    // Config menu - dirty / save bar
    ////////////////////////////
    ["elib.config.unsaved"]        = "Masz niezapisane zmiany.",
    // Polish has three plural forms; we use two buckets ("1" vs "many") same
    // as English - the nuance is lost but the result still reads naturally.
    ["elib.config.unsaved_one"]    = "%d niezapisana zmiana",
    ["elib.config.unsaved_many"]   = "%d niezapisanych zmian",

    ////////////////////////////
    // Config menu - switch-away prompt
    ////////////////////////////
    ["elib.config.switch.title"]    = "Niezapisane zmiany",
    ["elib.config.switch.body"]     = "Masz niezapisane zmiany. Przełączyć mimo to?",
    ["elib.config.switch.save"]     = "Zapisz i przełącz",
    ["elib.config.switch.discard"]  = "Odrzuć i przełącz",
    ["elib.config.switch.cancel"]   = "Anuluj",

    ////////////////////////////
    // Config menu - notifications
    ////////////////////////////
    ["elib.config.notify.saved_title"]      = "Konfiguracja",
    ["elib.config.notify.saved_body"]       = "Zmiany zapisane.",
    ["elib.config.notify.reverted_title"]   = "Konfiguracja",
    ["elib.config.notify.reverted_body"]    = "Zmiany cofnięte.",
    ["elib.config.notify.discarded_title"]  = "Konfiguracja",
    ["elib.config.notify.discarded_body"]   = "Menu zamknięte - niezapisane zmiany odrzucone.",

    ////////////////////////////
    // Color picker
    ////////////////////////////
    ["elib.colorpicker.title"] = "Wybierz kolor",

    ////////////////////////////
    // Validation messages
    ////////////////////////////
    ["elib.validation.min_length"]     = "Minimum %d znaków",
    ["elib.validation.max_length"]     = "Maksimum %d znaków",
    ["elib.validation.invalid_format"] = "Nieprawidłowy format",
    ["elib.validation.not_a_number"]   = "Musi być liczbą",
    ["elib.validation.min_value"]      = "Minimum %s",
    ["elib.validation.max_value"]      = "Maksimum %s",
    ["elib.validation.invalid_json"]   = "Nieprawidłowy JSON",

    ////////////////////////////
    // Notifications (generic)
    ////////////////////////////
    ["elib.notify.info"]    = "Informacja",
    ["elib.notify.success"] = "Sukces",
    ["elib.notify.warning"] = "Ostrzeżenie",
    ["elib.notify.error"]   = "Błąd",

    ////////////////////////////
    // Permissions / generic errors
    ////////////////////////////
    ["elib.error.no_permission"] = "Nie masz uprawnień do tej akcji.",
    ["elib.error.invalid_value"] = "Nieprawidłowa wartość.",
    ["elib.error.unknown"]       = "Coś poszło nie tak.",
})