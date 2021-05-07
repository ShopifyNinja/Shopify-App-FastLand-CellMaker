class CreateTimezone < ActiveRecord::Migration[6.0]
  def change
    create_table :timezones do |t|
      t.string :value, null: false
      t.string :label, null: false
    end

    execute "INSERT INTO `timezones` (`id`, `value`, `label`) VALUES
    (1, '-12:00',   '(GMT -12:00) Eniwetok, Kwajalein'),
    (2, '-11:00',   '(GMT -11:00) Midway Island, Samoa'),
    (3, '-10:00',   '(GMT -10:00) Hawaii'),
    (4, '-09:50',   '(GMT -9:30) Taiohae'),
    (5, '-09:00',   '(GMT -9:00) Alaska'),
    (6, '-08:00',   '(GMT -8:00) Pacific Time (US & Canada)'),
    (7, '-07:00',   '(GMT -7:00) Mountain Time (US & Canada)'),
    (8, '-06:00',   '(GMT -6:00) Central Time (US & Canada), Mexico City'),
    (9, '-05:00',   '(GMT -5:00) Eastern Time (US & Canada), Bogota, Lima'),
    (10,    '-04:50',   '(GMT -4:30) Caracas'),
    (11,    '-04:00',   '(GMT -4:00) Atlantic Time (Canada), Caracas, La Paz'),
    (12,    '-03:50',   '(GMT -3:30) Newfoundland'),
    (13,    '-03:00',   '(GMT -3:00) Brazil, Buenos Aires, Georgetown'),
    (14,    '-02:00',   '(GMT -2:00) Mid-Atlantic'),
    (15,    '-01:00',   '(GMT -1:00) Azores, Cape Verde Islands'),
    (16,    '+00:00',   '(GMT) Western Europe Time, London, Lisbon, Casablanca'),
    (17,    '+01:00',   '(GMT +1:00) Brussels, Copenhagen, Madrid, Paris'),
    (18,    '+02:00',   '(GMT +2:00) Kaliningrad, South Africa'),
    (19,    '+03:00',   '(GMT +3:00) Baghdad, Riyadh, Moscow, St. Petersburg'),
    (20,    '+03:50',   '(GMT +3:30) Tehran'),
    (21,    '+04:00',   '(GMT +4:00) Abu Dhabi, Muscat, Baku, Tbilisi'),
    (22,    '+04:50',   '(GMT +4:30) Kabul'),
    (23,    '+05:00',   '(GMT +5:00) Ekaterinburg, Islamabad, Karachi, Tashkent'),
    (24,    '+05:50',   '(GMT +5:30) Bombay, Calcutta, Madras, New Delhi'),
    (25,    '+05:75',   '(GMT +5:45) Kathmandu, Pokhar'),
    (26,    '+06:00',   '(GMT +6:00) Almaty, Dhaka, Colombo'),
    (27,    '+06:50',   '(GMT +6:30) Yangon, Mandalay'),
    (28,    '+07:00',   '(GMT +7:00) Bangkok, Hanoi, Jakarta'),
    (29,    '+08:00',   '(GMT +8:00) Beijing, Perth, Singapore, Hong Kong'),
    (30,    '+08:75',   '(GMT +8:45) Eucla'),
    (31,    '+09:00',   '(GMT +9:00) Tokyo, Seoul, Osaka, Sapporo, Yakutsk'),
    (32,    '+09:50',   '(GMT +9:30) Adelaide, Darwin'),
    (33,    '+10:00',   '(GMT +10:00) Eastern Australia, Guam, Vladivostok'),
    (34,    '+10:50',   '(GMT +10:30) Lord Howe Island'),
    (35,    '+11:00',   '(GMT +11:00) Magadan, Solomon Islands, New Caledonia'),
    (36,    '+11:50',   '(GMT +11:30) Norfolk Island'),
    (37,    '+12:00',   '(GMT +12:00) Auckland, Wellington, Fiji, Kamchatka'),
    (38,    '+12:75',   '(GMT +12:45) Chatham Islands'),
    (39,    '+13:00',   '(GMT +13:00) Apia, Nukualofa'),
    (40,    '+14:00',   '(GMT +14:00) Line Islands, Tokelau');"
  end
end
