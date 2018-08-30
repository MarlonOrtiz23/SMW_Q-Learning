acoes = {"P1 Right","P1 X","P1 A","P1 B"}; -- 2; 3; 4; 2,3; 2,4
comandos = {};
inicio = "inicio.state"
qtable = {};

function getElementos()
	posX = memory.read_s16_le(0x94);
	posY = memory.read_s16_le(0x96);
	
	posXtela = memory.read_s16_le(0x7E);
	posYtela = memory.read_s16_le(0x80);
	
	score = memory.read_s24_le(0xF34)
	
	blocos = memory.readbyterange(0x1BE6,256);
	
	inimigosID = memory.readbyterange(0x9E,12);
	inimigosStatus = memory.readbyterange(0x14C8,12);
	
	marioMorre = memory.readbyte(0x71); -- 9 = morte
	
	spritesX1 = memory.readbyterange(0x14E8,24);
	spritesX2 = memory.readbyterange(0xE4,24);
	spritesY1 = memory.readbyterange(0x14D4,24);
	spritesY2 = memory.readbyterange(0xD8,24);
	
end

function resetControl()
	for i = 1, 4 do
		comandos[acoes[i]] = false;
	end
	joypad.set(comandos);
end

--https://www.lua.org/pil/12.1.1.html
function serialize (o)
	if type(o) == "number" then
		io.write(o)
	elseif type(o) == "string" then
		io.write(string.format("%q", o))
	elseif type(o) == "table" then
		io.write("{\n")
		for k,v in pairs(o) do
			io.write("  ", k, " = ")
			serialize(v)
			io.write(",\n")
		end
		io.write("}\n")
	else
		error("cannot serialize a " .. type(o))
	end
end

savestate.load(inicio);
estado = 0;
objetivoX = 4840;
posXanterior = 0;
score = 0;
posX = 0;

results = 0;


while true do
	posXanterior = posX;
	
	scoreAnterior = score;
	
	--recompensa = posX - posXanterior;
	
	getElementos();
	
	--print("pos x tela " .. posXtela);
	--print("pos y tela " .. posYtela);
	--print("pos x mundo " .. posX);
	--print("pos y mundo " .. posY);
	--print("");
	
	estado = posX .. 000 .. posY;
	
	acao = 0;
	
	--print("estado " .. estado);
	
	if qtable[estado] == nil then -- estado novo
		--print("qtable nil");
		qtable[estado] = {};
		for i = 2,6 do
			qtable[estado][i] = 0;
		end
		acao = math.random(2,6);
	end
	
	if acao == 0 then -- já passou nesse estado
		r = math.random(0,100);
		if r < 5 then -- % de chance
			acao = math.random(2,6);
			print("acao randomica tomada");
		else
			melhor = 0;
			indice = 0;
			for i = 2, 6 do
				if qtable[estado][i] >= melhor then
					melhor = qtable[estado][i];
					indice = i;
				end
			end
			print("melhor acao tomada");
			acao = indice;
		end
	end
	
	--savestate.save("estados/estado" .. estado);
	
	resetControl();
	comandos[acoes[1]] = true; -- ir para direita
		
	if acao < 5 then
		comandos[acoes[acao]] = true;
	end
	
	if acao == 5 then -- X + A
		comandos[acoes[2]] = true;
		comandos[acoes[3]] = true;		
	end
	
	if acao == 6 then -- X + B
		comandos[acoes[2]] = true;
		comandos[acoes[4]] = true;		
	end
	
	ver = 0;
	
	for i = 1, 6 do
		joypad.set(comandos);
		emu.frameadvance();
		getElementos();		
		if marioMorre == 9 then
			qtable[estado][acao] = -100;			
			ver =  1;
			savestate.load(inicio);
			break;
		end
	end
	
	if posX > objetivoX then
		print ("objetivo alcançado!\n");
		file = io.open("score.txt","a+");
		io.output(file);
		io.write("\n");
		io.write(score);
		io.close(file);
		results = results+1;
		if results == 10 then
			break;
		end
		savestate.load(inicio);
		qtable[estado][acao] = 100;
		ver = 1;
	end
	
	--recompensa
	
	recompensa = (score - scoreAnterior) + ((posX - posXanterior)/10);
	if ver == 0 then
		if qtable[estado][acao] < recompensa then
			qtable[estado][acao] = recompensa;
		end
	end
	
	--qtable[estado] = posX-posXanterior;
	--estado = estado+1;
	
end