program laberinto;
uses crt;

type 
	xy = record
		posx : integer;
		posy : integer;
	end;

	// union
	lab_elem = record
		case elem : char of
			'v' : (via : byte);
			'p' : (pared: byte);
			's' : (salida : byte);
			'j' : (jugador : byte);
			'm' : (monstruo : byte;
				   xy_monstruo : xy; );
	end;



const
	// tamaño del laberinto 75x21
	lab_alto = 21;
	lab_ancho = 75;

	// representan el dibujo del borde del laberinto 76x22
	borde_x0 = 4;
	borde_y0 = 4;
	borde_alto = 22;
	borde_ancho = 76;

var
	// representacion del laberinto
	maze: array [1..lab_alto, 1..lab_ancho] of lab_elem;
	// recorren las columnas(ancho) y filas(alto) del laberinto
	x, y: integer;
	// posicion actual del jugador
	xy_jugador : xy;
	// posicion actual del (los) monstruo(s)
	xy_salida : xy;
	// archivo desde el cual se cargara el laberinto
	archivo: text;
	// linea leida del archivo
	line: string;
	// entrada del teclado
	input: char;
	// n_x, cantidad de columnas a desplazar (izquierda/derecha)
	// n_y, cantidad de filas a desplazar (arriba/abajo)
	n_x, n_y: integer;
	// nivel de dificultad escogido por el usuario
	nivel: char;
	// cantidad de monstruos en el laberinto
	n_monstruos: integer;
	// identificador para cada monstruo, se coloca el maximo posible (13)
	monstruos : array [1..13] of lab_elem;
	// recorre el arreglo de 'monstruos'
	i: integer;
	// cantidad de pasos dados en el laberinto
	pasos: integer;

// dibuja en una posicion (x,y) una pieza(paredes, jugador, salida) del laberinto de un color
procedure dibujar(x, y: integer; pieza: char; color: word);
begin
	textcolor(color);
	gotoxy(x, y);
	write(pieza);
end;

// dibuja un borde que delimita el area de juego
procedure dibujar_borde();
begin
	gotoxy(borde_x0, 1);

	// borde superior e inferior
	for x := borde_x0 to borde_x0 + borde_ancho do
	begin
		dibujar(x, borde_y0, '#', cyan);
		dibujar(x, borde_y0 + borde_alto, '#', cyan);
	end;

	// bordes laterales
	for y := borde_y0 to borde_y0 + borde_alto do
	begin
		dibujar(borde_x0, y, '#', cyan);
		dibujar(borde_x0 + borde_ancho, y, '#', cyan);
	end;
end;

// carga en 'maze' el laberinto desde el archivo de texto
// @param filename, nombre del archivo a leer
procedure cargar_lab(filename: string);
begin
	n_monstruos := 0;
	//setlength(monstruos,1);
	assign(archivo, filename);
	reset(archivo);

	for y := 1 to lab_alto do
	begin
		readln(archivo, line);

		for x := 1 to lab_ancho do
		begin
			case line[x] of
				' ' :
					begin
						maze[y, x].elem := 'v';
						maze[y, x].via := 0;
					end;
				'#' :
					begin
						maze[y, x].elem := 'p';
						maze[y, x].pared := 1;
					end;
				'P' :
					begin
						maze[y, x].elem := 'j';
						maze[y, x].jugador := 254;
						xy_jugador.posx := x;
						xy_jugador.posy := y;
					end;
				// inicializo posicion del monstruo
				'@' :
					begin
						maze[y, x].elem := 'm';
						maze[y, x].monstruo := 253;
						maze[y, x].xy_monstruo.posx := x;
						maze[y, x].xy_monstruo.posy := y;
						n_monstruos += 1;
 						// copy(monstruos,1,n_monstruos);
						monstruos[n_monstruos] := maze[y, x];
					end;
				'E' :
					begin
						maze[y, x].elem := 's';
						maze[y, x].salida := 255;
						xy_salida.posx := x;
						xy_salida.posy := y;
					end;
			end;
		end;
	end;

	close(archivo);
end;

// dibuja el laberinto.
procedure dibujarlab();
begin
	for y := 1 to lab_alto do
	begin
		for x := 1 to lab_ancho do
		begin
			case maze[y, x].elem of
				'v' :dibujar(x + borde_x0, y + borde_y0, ' ', white);
				'p' : dibujar(x + borde_x0, y + borde_y0, '#', lightcyan);
				's' : dibujar(x + borde_x0, y + borde_y0, 'E', lightmagenta);
				'j' : dibujar(x + borde_x0, y + borde_y0, 'P', yellow);
				'm' :
					begin
						for i := 1 to n_monstruos do
						begin
							dibujar(monstruos[i].xy_monstruo.posx + borde_x0,
										monstruos[i].xy_monstruo.posy + borde_y0,
										'@', lightred);
						end;
					end;
			end;
		end;
	end;
end;

// Indica si se puede mover el 'jugador' o el 'monstruo' a la posicion (x,y).
// 'monstruo' se puede mover sobre el 'jugador' pero no sobre la 'salida'.
// 'jugador' se puede mover sobre la 'salida' pero no sobre 'monstruo'
// @param (x,y), posicion a la cual quiero verificar si se puede hacer el movimiento
// @param es_m, indica si el que se va mover es el 'monstruo'
function puedo_mover(x, y: integer; es_m: boolean): boolean;
begin
	// verificar que estamos en el area delimitada y la posicion
	// (x,y) <> '#' (no nos movemos sobre una pared)
	if (x > 0 ) and (x <= lab_ancho) and (y > 0) and (y <= lab_alto)
			and (maze[y,x].elem <> 'p') then
	begin
		if es_m then
		begin // Debo verificar para cada monstruo en el arreglo
			puedo_mover := ( (maze[y,x].elem = 'v') or (maze[y,x].elem = 'j') ) and
									(maze[y,x].elem <> 's');
		end
		else puedo_mover := ( (maze[y,x].elem = 'v') or (maze[y,x].elem = 's') ) and
											(maze[y,x].elem <> 'm');
	end;
end;

// Intenta al 'jugador' o 'monstruo' segun sea el caso, e indica si tuvo exito(true) o no(false)
// @param (x,y), posicion inicial
// @param es_m, indica si el que se va mover es el 'monstruo'
// @param (new_x, new_y), retorna la nueva posicion a la cual se hizo el movimiento
function mover(x, y, n_x, n_y: integer; es_m: boolean; var new_x: integer; var new_y: integer): boolean;
begin
	if puedo_mover(x + n_x, y + n_y, es_m) then
	begin
		// nueva posicion a la cual se desea mover
		new_x := x + n_x;
		new_y := y + n_y;
		
		// en donde estaba ahora es una via libre
		maze[y,x].elem := 'v';

		// actualizo posicion
		if es_m then maze[new_y,new_x].elem := 'm'
		else maze[new_y,new_x].elem := 'j';

		mover := true;
	end
	else mover := false;
end;

// mover monstruo dependiendo de la posicion del jugador
// @param m, monstruo que se va a mover; lo devuelve con sus posiciones modificadas
procedure mover_monstruo(var m: xy);
begin
	n_x := 0;
	n_y := 0;

	// desplazo hacia la inzquierda/derecha el monstruo, si no esta
	// al mismo nivel que el jugador
	if (xy_jugador.posx < m.posx) then n_x := -1
	else if (xy_jugador.posx > m.posx) then n_x := 1;

	// desplazo el monstruo hacia arriba/abajo, si no esta
	// al mismo nivel que el jugador
	if (xy_jugador.posy < m.posy) then n_y := -1
	else if (xy_jugador.posy > m.posy) then n_y := 1;

	// si el monstruo se puede desplazar n_x columnas, entonces verifica
	// si el movimiento tiene exito
	if (n_x <> 0) then
	begin
		if mover(m.posx, m.posy, n_x, 0, true, m.posx, m.posy) then exit; // de la rutina
	end;

	// si el monstruo se puede desplazar n_y filas, entonces verifica
	// si el movimiento tiene exito
	if (n_y <> 0) then
	begin
		if mover(m.posx, m.posy, 0, n_y, true, m.posx, m.posy) then exit; // de la rutina
	end;

	// verificamos que no nos movemos hacia el jugador??
	if mover(m.posx, m.posy, 0, -n_y, true, m.posx, m.posy) then exit; // de la rutina

	mover(m.posx, m.posy, -n_x, 0, true, m.posx, m.posy);
end;

// mover jugador
// @param n_x, cantidad de columnas desplazadas (izquierda/derecha)
// @param n_y, cantidad de lineas desplazadas (arriba/abajo)
procedure mover_jugador(n_x, n_y: integer);
begin
	if mover(xy_jugador.posx, xy_jugador.posy, n_x, n_y, false, xy_jugador.posx, xy_jugador.posy) then
	begin
		pasos := pasos + 1;
		gotoxy(1,2);
		writeln('pasos: ',pasos);
	end;
end;

// determina si el jugador llego a la salida
function salio(): boolean;
begin
	salio := (xy_jugador.posy = xy_salida.posy) and (xy_jugador.posx = xy_salida.posx);
end;

// determina si el jugador murio
function murio(): boolean;
begin
	for i := 1 to n_monstruos do
	begin
		if (xy_jugador.posx = monstruos[i].xy_monstruo.posx) and
			(xy_jugador.posy = monstruos[i].xy_monstruo.posy) then murio := true;
	end;
end;

// maneja la logica para jugar
procedure jugar();
begin
	pasos := 0;
	writeln('q -> salir');
	writeln('pasos: ',pasos);
	dibujar_borde();
	dibujarlab();

	// muevo jugador con las flechas
	repeat
		input := readkey();
		n_x:= 0;
		n_y:= 0;

		case input of
			'j' : n_x := -1;	// moverse a la izquierda
			'i' : n_y := -1;	// moverse hacia arriba
			'l' : n_x := 1;	// moverse a la derecha
			'k' : n_y := 1; 	// moverse hacia abajo
		end;

		mover_jugador(n_x,n_y);
		for i := 1 to n_monstruos do mover_monstruo(monstruos[i].xy_monstruo);
		dibujarlab();
	until (input = 'q') or salio() or murio();
end;

procedure menu();
begin
	// titulo: maze runer
	textcolor(lightmagenta);
	writeln();
	writeln('  **     **   ****    *******  ******    ');
	writeln('  ***   ***  **  **       **   **        ');
	writeln('  **  *  **  ******    ****    ****      ');
	writeln('  **     **  **  **   **       **        ');
	writeln('  **     **  **  **  *******   ******    ');
	writeln();
	writeln('  *****   **  **  **   **  ******  *****');
	writeln('  **  **  **  **  ***  **  **      **  **');
	writeln('  *****   **  **  ** * **  ****    *****');
	writeln('  **  **  ******  **  ***  **      **  **');
	writeln('  **  **  ******  **   **  ******  **  **');
	writeln('');

	textcolor(lightblue);
	gotoxy(5,14);
	writeln('escoge un nivel y presiona <enter>');
	gotoxy(5,15);
	writeln('a -> facil');
	gotoxy(5,16);
	writeln('b -> medio');
	gotoxy(5,17);
	writeln('c -> dificil');
	gotoxy(5,18);
	writeln('d -> extremo');
	gotoxy(5,19);
	writeln('e -> intentalo si puedes');
	gotoxy(5,20);
	writeln('q -> salir');
	writeln();
	gotoxy(5,22);
	readln(nivel);
end;

procedure main();
begin
	clrscr();
	cursoroff();
	menu();
	clrscr();

	// uso del menu
	while true do
	begin
		case nivel of
			'a': begin cargar_lab('facil.txt'); break; end;
			'b': begin cargar_lab('medio.txt'); break; end;
			'c': begin cargar_lab('dificil.txt'); break; end;
			'd': begin cargar_lab('extremo.txt'); break; end;
			'e': begin cargar_lab('muajajaja.txt'); break; end;
			'q': begin normvideo; exit; end;
			else writeln('ingresa una opcion valida'); menu();
		end;
	end;
	
	clrscr();
	
	jugar();

	clrscr();

	if salio() then
	begin
		textcolor(lightblue);
		writeln('    excelente!!!!');
		writeln('    has ganado');
		writeln('       +++++');
		writeln('     ++     ++');
		writeln('    +         +');
		writeln('   +           +');
		writeln('   +           +');
		writeln('  +++++++++++++++');
		writeln('  + ++  ++++  + +');
		writeln('  + +++ + +++ + +');
		writeln('  +  +++   +++  +');
		writeln('  +             +');
		writeln('   +  +        +');
		writeln('   +   ++++    +');
		writeln('    +         +');
		writeln('     ++     ++');
		writeln('       +++++');
	end // if
	else if murio() then
	begin
		textcolor(red);
		writeln('      has muerto');
		writeln('        +++++');
		writeln('      +       +');
		writeln('     +         +');
		writeln('     + ++   ++ +');
		writeln('     + ++   ++ +');
		writeln('      +   +   +');
		writeln('       +     +');
		writeln('         +++');
		writeln('     ++        ++');
		writeln('   +   ++    ++   +');
		writeln('  +     ++ ++      +');
		writeln('    ++    +    ++');
		writeln('       ++   ++');
		writeln('    ++    +    ++');
		writeln('  +     ++ ++      +');
		writeln('   +  ++     ++   +');
		writeln('     +          +');
	end // else if
	else
	begin
		textcolor(blue);
		writeln('    no terminaste');
		writeln('        ++++++');
		writeln('      ++++++++++');
		writeln('     ++++++++++++');
		writeln('    ++++++++++++++');
		writeln('   ++++++++++++++++');
		writeln('   ++++++++++++++++');
		writeln('  ++++   ++++   ++++');
		textcolor(yellow);
		writeln('  +++    ++++    +++');
		writeln('  +++   ++++++   +++');
		writeln('  +++  ++++++++  +++');
		writeln('  ++++++++++++++++++');
		writeln('  ++++++++  ++++++++');
		writeln('   +++++++  +++++++');
		writeln('   +  ++++  ++++  +');
		writeln('   +   +++  +++   +');
		writeln('    +    ++++     +');
		writeln('     +  ++++++  +');
		writeln('     +  + ++ +  +');
	end;
	writeln('');

	cursoron();

	normvideo;		// colores por defecto de la consola
end;

// Ejecutar
begin
	main();
end.
