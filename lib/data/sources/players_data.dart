/// Real, recognisable player names for each nation, in position order:
/// [GK, DEF, DEF, DEF, DEF, MID, MID, MID, FWD, FWD, FWD].
/// Used for lineups and goalscorers so the match detail feels genuine.
/// (Representative starting elevens — squads evolve, but names are real.)
const Map<String, List<String>> kSquads = {
  // Group A
  'mex': ['Ochoa', 'J. Sánchez', 'Montes', 'Vásquez', 'Gallardo', 'E. Álvarez', 'L. Chávez', 'O. Pineda', 'Lozano', 'R. Jiménez', 'S. Giménez'],
  'rsa': ['Williams', 'Mudau', 'Modiba', 'Xulu', 'Mbatha', 'Mokoena', 'Zwane', 'Sithole', 'Mofokeng', 'Tau', 'Maboe'],
  'kor': ['Jo Hyeon-woo', 'Kim Min-jae', 'Kim Young-gwon', 'Kim Jin-su', 'Lee Ki-je', 'Hwang In-beom', 'Lee Jae-sung', 'Park Yong-woo', 'Hwang Hee-chan', 'Son Heung-min', 'Cho Gue-sung'],
  'cze': ['Staněk', 'Coufal', 'Hranáč', 'Krejčí', 'Zima', 'Souček', 'Provod', 'Barák', 'Černý', 'Schick', 'Hložek'],
  // Group B
  'can': ['Crépeau', 'Johnston', 'Vitória', 'Miller', 'Davies', 'Eustáquio', 'Koné', 'Buchanan', 'David', 'Larin', 'Millar'],
  'bih': ['Šehić', 'Kolašinac', 'Bičakčić', 'Ahmedhodžić', 'Katić', 'Pjanić', 'Tahirović', 'Gigović', 'Bajraktarević', 'Džeko', 'Demirović'],
  'qat': ['Barsham', 'Pedro Miguel', 'Khoukhi', 'B. Hassan', 'Ahmed', 'Hatem', 'Boudiaf', 'Al Haydos', 'Afif', 'Almoez Ali', 'Muntari'],
  'sui': ['Sommer', 'Widmer', 'Akanji', 'Schär', 'Rodríguez', 'Freuler', 'Xhaka', 'Sow', 'Shaqiri', 'Embolo', 'Ndoye'],
  // Group C
  'bra': ['Alisson', 'Danilo', 'Marquinhos', 'Gabriel', 'Wendell', 'Bruno G.', 'Casemiro', 'Paquetá', 'Raphinha', 'Vinícius Jr', 'Rodrygo'],
  'mar': ['Bounou', 'Hakimi', 'Aguerd', 'Saïss', 'Mazraoui', 'Amrabat', 'Ounahi', 'Amallah', 'Ziyech', 'En-Nesyri', 'Boufal'],
  'hai': ['Placide', 'Boco', 'Mondésir', 'Lafrance', 'Camélien', 'Saint-Juste', 'Vincent', 'Casimir', 'Pierrot', 'Bazile', 'Étienne'],
  'sco': ['Gunn', 'Hickey', 'Tierney', 'Hanley', 'Robertson', 'McTominay', 'McGinn', 'Gilmour', 'Adams', 'Dykes', 'McGregor'],
  // Group D
  'usa': ['Turner', 'Dest', 'Richards', 'Robinson', 'A. Robinson', 'Adams', 'McKennie', 'Musah', 'Pulisic', 'Balogun', 'Weah'],
  'par': ['Coronel', 'Espínola', 'G. Gómez', 'Balbuena', 'Alonso', 'Cubas', 'Villasanti', 'Almirón', 'Sanabria', 'Enciso', 'Bareiro'],
  'aus': ['Ryan', 'Atkinson', 'Souttar', 'Rowles', 'Behich', 'Mooy', 'Irvine', 'McGree', 'Leckie', 'Duke', 'Goodwin'],
  'tur': ['Çakır', 'Çelik', 'Demiral', 'Akaydın', 'Kadıoğlu', 'Çalhanoğlu', 'Kökçü', 'Güler', 'Yıldız', 'Aktürkoğlu', 'Yılmaz'],
  // Group E
  'ger': ['Neuer', 'Kimmich', 'Tah', 'Rüdiger', 'Raum', 'Andrich', 'Gündoğan', 'Wirtz', 'Sané', 'Havertz', 'Musiala'],
  'cuw': ['Room', 'J. Bacuna', 'Martina', 'Hooi', 'Sno', 'L. Bacuna', 'Antonia', 'Bombita', 'Janga', 'Sint-Jago', 'Garcia'],
  'civ': ['Fofana', 'Singo', 'Ndicka', 'Boly', 'Aurier', 'Seri', 'Kessié', 'Sangaré', 'Pépé', 'Haller', 'Gradel'],
  'ecu': ['Galíndez', 'Preciado', 'F. Torres', 'Hincapié', 'Estupiñán', 'Caicedo', 'Franco', 'Plata', 'Páez', 'E. Valencia', 'K. Rodríguez'],
  // Group F
  'ned': ['Verbruggen', 'Dumfries', 'De Vrij', 'Van Dijk', 'Aké', 'De Jong', 'Reijnders', 'Gravenberch', 'Gakpo', 'Depay', 'Simons'],
  'jpn': ['Suzuki', 'Sugawara', 'Itakura', 'Tomiyasu', 'Nakayama', 'Endo', 'Morita', 'Kubo', 'Mitoma', 'Ueda', 'Doan'],
  'swe': ['Olsen', 'Krafth', 'Lindelöf', 'Hien', 'Augustinsson', 'Olsson', 'Bénie', 'Forsberg', 'Kulusevski', 'Isak', 'Gyökeres'],
  'tun': ['Dahmen', 'Drager', 'Talbi', 'Bronn', 'Abdi', 'Skhiri', 'Laidouni', 'Ben Romdhane', 'Msakni', 'Khazri', 'Jebali'],
  // Group G
  'bel': ['Casteels', 'Castagne', 'Faes', 'Theate', 'De Cuyper', 'Onana', 'Tielemans', 'De Bruyne', 'Doku', 'Lukaku', 'Trossard'],
  'egy': ['El Shenawy', 'Hamdy', 'Hegazi', 'Abdelmonem', 'Fatouh', 'Elneny', 'Attia', 'Trezeguet', 'Marmoush', 'Salah', 'Mostafa'],
  'irn': ['Beiranvand', 'Moharrami', 'Hosseini', 'Pouraliganji', 'Mohammadi', 'Ezatolahi', 'Noorollahi', 'Gholizadeh', 'Jahanbakhsh', 'Taremi', 'Azmoun'],
  'nzl': ['Crocombe', 'Boxall', 'Tuiloma', 'Surman', 'Cacace', 'Garbett', 'Bell', 'Stamenić', 'Wood', 'Barbarouses', 'Just'],
  // Group H
  'esp': ['Simón', 'Carvajal', 'Le Normand', 'Laporte', 'Cucurella', 'Rodri', 'Pedri', 'Gavi', 'Yamal', 'Morata', 'N. Williams'],
  'cpv': ['Vozinha', 'Ponck', 'Lopes', 'Tavares', 'D. Mendes', 'Cabral', 'Pico', 'Semedo', 'Rodrigues', 'Andrade', 'Livramento'],
  'ksa': ['Al-Owais', 'Al-Ghannam', 'Al-Bulaihi', 'Al-Amri', 'Al-Shahrani', 'Kanno', 'Al-Faraj', 'Al-Dawsari', 'Al-Buraikan', 'Al-Shehri', 'Al-Najei'],
  'uru': ['Rochet', 'Nández', 'J. Giménez', 'Araújo', 'Olivera', 'Valverde', 'Bentancur', 'Ugarte', 'Pellistri', 'Núñez', 'M. Araújo'],
  // Group I
  'fra': ['Maignan', 'Koundé', 'Saliba', 'Upamecano', 'T. Hernández', 'Tchouaméni', 'Camavinga', 'Griezmann', 'Dembélé', 'Mbappé', 'Thuram'],
  'sen': ['É. Mendy', 'Sabaly', 'Koulibaly', 'Niakhaté', 'Jakobs', 'I. Gueye', 'P. Gueye', 'N. Mendy', 'Sarr', 'Mané', 'Dia'],
  'irq': ['Jalal', 'Ali Faez', 'Bayesh', 'Adnan', 'Rashid', 'Resan', 'Ali Jasim', 'Hussein', 'Aymen', 'Hardan', 'Mohammed'],
  'nor': ['Nyland', 'Ryerson', 'Ajer', 'Østigård', 'Wolfe', 'Berge', 'Ødegaard', 'Aursnes', 'Sørloth', 'Haaland', 'Nusa'],
  // Group J
  'arg': ['E. Martínez', 'Molina', 'Romero', 'Otamendi', 'Tagliafico', 'De Paul', 'Mac Allister', 'E. Fernández', 'Messi', 'J. Álvarez', 'Di María'],
  'alg': ['Mandréa', 'Mandi', 'Bensebaini', 'Tougai', 'Aït-Nouri', 'Bennacer', 'Zerrouki', 'Mahrez', 'Gouiri', 'Amoura', 'Belaïli'],
  'aut': ['Pentz', 'Posch', 'Danso', 'Lienhart', 'Mwene', 'Seiwald', 'Laimer', 'Sabitzer', 'Baumgartner', 'Arnautović', 'Gregoritsch'],
  'jor': ['Shafi', 'Nasib', 'Abdullah', 'Haddad', 'Lafi', 'Al-Rashdan', 'Al-Mardi', 'Al-Naimat', 'Al-Tamari', 'Olwan', 'Abu Zraiq'],
  // Group K
  'por': ['Diogo Costa', 'Cancelo', 'Pepe', 'Rúben Dias', 'N. Mendes', 'Palhinha', 'B. Fernandes', 'Vitinha', 'B. Silva', 'Ronaldo', 'Leão'],
  'cod': ['Mpasi', 'Masuaku', 'Mbemba', 'Mukau', 'Wan-Bissaka', 'Moutoussamy', 'Pickel', 'Bakambu', 'Wissa', 'Bayo', 'Elia'],
  'uzb': ['Yusupov', 'Khusanov', 'Abdukholikov', 'Egamberdiev', 'Khojiakbarov', 'Iskanderov', 'Urunov', 'Masharipov', 'Fayzullaev', 'Shomurodov', 'Turgunboev'],
  'col': ['Vargas', 'Muñoz', 'S. Arias', 'Lucumí', 'Mojica', 'Lerma', 'Uribe', 'J. Rodríguez', 'L. Díaz', 'Borré', 'Córdoba'],
  // Group L
  'eng': ['Pickford', 'Walker', 'Stones', 'Guéhi', 'Shaw', 'Rice', 'Bellingham', 'Foden', 'Saka', 'Kane', 'Palmer'],
  'cro': ['Livaković', 'Stanišić', 'Šutalo', 'Gvardiol', 'Sosa', 'Modrić', 'Brozović', 'Kovačić', 'Pašalić', 'Kramarić', 'Perišić'],
  'gha': ['Ati-Zigi', 'Lamptey', 'Djiku', 'Salisu', 'Mensah', 'Partey', 'Kudus', 'A. Ayew', 'J. Ayew', 'I. Williams', 'Semenyo'],
  'pan': ['Mosquera', 'Murillo', 'Andrade', 'Córdoba', 'Davis', 'Carrasquilla', 'Bárcenas', 'Godoy', 'Gondola', 'Fajardo', 'Waterman'],
};
