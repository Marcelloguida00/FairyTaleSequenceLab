import os

strings_to_add = {
    "en.lproj": {
        "ar.scan.title": "Room Scan...",
        "ar.scan.not_available": "Move the device to scan...",
        "ar.scan.limited": "Keep moving...",
        "ar.scan.extending": "Mapping in progress...",
        "ar.scan.mapped": "Almost ready!",
        "ar.scan.find_card": "Find the card:",
        "ar.scan.congrats": "Great job!",
        "ar.scan.found_all": "You found all the cards.",
        "ar.scan.correct": "Correct!"
    },
    "it.lproj": {
        "ar.scan.title": "Scansione Stanza...",
        "ar.scan.not_available": "Muovi il dispositivo...",
        "ar.scan.limited": "Continua a muoverti...",
        "ar.scan.extending": "Mappatura in corso...",
        "ar.scan.mapped": "Quasi pronto!",
        "ar.scan.find_card": "Cerca la carta:",
        "ar.scan.congrats": "Bravissimo!",
        "ar.scan.found_all": "Hai trovato tutte le carte.",
        "ar.scan.correct": "Esatto!"
    },
    "fa.lproj": {
        "ar.scan.title": "اسکن اتاق...",
        "ar.scan.not_available": "دستگاه را حرکت دهید...",
        "ar.scan.limited": "به حرکت ادامه دهید...",
        "ar.scan.extending": "در حال نقشه‌برداری...",
        "ar.scan.mapped": "تقریبا آماده است!",
        "ar.scan.find_card": "کارت را پیدا کن:",
        "ar.scan.congrats": "آفرین!",
        "ar.scan.found_all": "شما همه کارت‌ها را پیدا کردید.",
        "ar.scan.correct": "درست است!"
    },
    "ru.lproj": {
        "ar.scan.title": "Сканирование комнаты...",
        "ar.scan.not_available": "Перемещайте устройство...",
        "ar.scan.limited": "Продолжайте движение...",
        "ar.scan.extending": "Идет картирование...",
        "ar.scan.mapped": "Почти готово!",
        "ar.scan.find_card": "Найди карту:",
        "ar.scan.congrats": "Молодец!",
        "ar.scan.found_all": "Вы нашли все карты.",
        "ar.scan.correct": "Правильно!"
    },
    "sq.lproj": {
        "ar.scan.title": "Skanimi i Dhomës...",
        "ar.scan.not_available": "Lëvizni pajisjen...",
        "ar.scan.limited": "Vazhdoni të lëvizni...",
        "ar.scan.extending": "Hartëzimi në progres...",
        "ar.scan.mapped": "Gati gati!",
        "ar.scan.find_card": "Gjej kartën:",
        "ar.scan.congrats": "Të lumtë!",
        "ar.scan.found_all": "Ju i gjetët të gjitha kartat.",
        "ar.scan.correct": "Saktë!"
    }
}

base_dir = "/Users/marcelloguida/Desktop/Progetto FInale/Final Version/Final Version"

for lproj, translations in strings_to_add.items():
    file_path = os.path.join(base_dir, lproj, "Localizable.strings")
    
    # Read existing
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except:
        content = ""
        
    with open(file_path, "a", encoding="utf-8") as f:
        f.write("\n\n/* AR Scan Strings */\n")
        for key, val in translations.items():
            if f'"{key}"' not in content:
                f.write(f'"{key}" = "{val}";\n')

print("Strings added successfully!")
