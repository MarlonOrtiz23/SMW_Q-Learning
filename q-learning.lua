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

estado = 0;
objetivoX = 4823; --4823
posX = 0;
posXanterior = 0;
score = 0;
scoreAnterior = 0;

acao = 0;
currentValue = 0;
newValue = 0;
learningRate = 0.5;
discount = 0.5;

function q()
	getElementos();
	
	local estado = posX .. 000 .. posY;
	
	if qtable[estado] == nil then -- estado novo
		--print("qtable nil");
		qtable[estado] = {};
		for i = 2,6 do
			qtable[estado][i] = 0;
		end
		savestate.save("estados/" .. estado);
	else
		savestate.load("estados/" .. estado);
	end
	
	if posX > objetivoX then -- verifica o objetivo
		--getElementos();
		print ("objetivo alcançado!\n score: " .. score);
		file = io.open("scores.txt","a+");
		io.output(file);
		io.write("\n");
		io.write(score);		
		io.close(file);
		--savestate.load(inicio);
		qtable[estado][acao] = 100;
		return 100;
	end
	
	if posX <= posXanterior then
		return -10;
	end
	
	reward = (score - scoreAnterior) + ((posX - posXanterior)/10);
	
	posXanterior = posX;
	
	scoreAnterior = score;
	
	melhor = 0;
	
	for i = 2, 6 do -- para todas as ações
		--estado = posX .. 000 .. posY;
		savestate.load("estados/" .. estado);
		acao = i;
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
		
		for i = 1, 60 do -- realiza ação
			joypad.set(comandos);
			emu.frameadvance();
			getElementos();
			--print(marioMorre);
			if marioMorre == 9 then -- verifica se morreu
				qtable[estado][acao] = -100;			
				--savestate.load(inicio);
				return -100;
			end
		end
		
		aux = q();
		
		if aux > melhor then
			melhor = aux;
		end
	end
	
	qtable[estado][acao] = qtable[estado][acao] + (learningRate* (reward + (discount*melhor) - qtable[estado][acao]));
	
	return qtable[estado][acao];
	
end


for i = 1, 1 do
	savestate.load(inicio);
	--getElementos();
	
	q();
	
	print("treino finalizado \n");
	
	while true do
		savestate.load(inicio);		
		while posX < objetivoX do
			getElementos();
			estado = posX .. 000 .. posY;
			resetControl();
			comandos[acoes[1]] = true; -- ir para direita
			melhor = 0;
			for i = 2, 6 do -- para todas as ações
				aux = qtable[estado][i];
				if aux > melhor then
					melhor = aux;
				end
			end
			
			acao = i;
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
			
			for i = 1, 60 do -- realiza ação
				joypad.set(comandos);
				emu.frameadvance();
			end
			getElementos();
		end
	end
	
end