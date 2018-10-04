acoes = {"P1 Right","P1 X","P1 A","P1 B"}; -- 2; 3; 4; 2,3; 2,4
comandos = {};
inicio = "inicio.state"
states = {};

function getElementos()
	posX = memory.read_s16_le(0x94);
	posY = memory.read_s16_le(0x96);
	
	posXtela = memory.read_s16_le(0x7E);
	posYtela = memory.read_s16_le(0x80);
	
	score = memory.read_s24_le(0xF34);
	
	blocosAux = memory.readbyterange(0x1BE6,256);
	--print("blocosAux[0] " .. blocosAux[0]);
	blocos = "";
	for i = 0, 255 do
		--print(i .. " ");
		blocos = blocos .. "0" .. blocosAux[i];
	end
	
	inimigosID = "";
	inimigosIDaux = memory.readbyterange(0x9E,12);
	for i = 0, 11 do
		inimigosID = inimigosID .. "0" .. inimigosIDaux[i];
	end
	
	inimigosStatus = "";
	inimigosStatusaux = memory.readbyterange(0x14C8,12); -- verificar o status!!!
	for i = 0, 11 do
		inimigosStatus = inimigosStatus .. "0" .. inimigosStatusaux[i];
	end
	
	marioMorre = memory.readbyte(0x71); -- 9 = morte
	
	spritesX1 = "";
	spritesX2 = "";
	spritesY1 = "";
	spritesY2 = "";
	spritesX1aux = memory.readbyterange(0x14E8,24);
	for i = 0, 23 do
		spritesX1 = spritesX1 .. "0" .. spritesX1aux[i];
	end
	spritesX2aux = memory.readbyterange(0xE4,24);
	for i = 0, 23 do
		spritesX2 = spritesX2 .. "0" .. spritesX2aux[i];
	end
	spritesY1aux = memory.readbyterange(0x14D4,24);
	for i = 0, 23 do
		spritesY1 = spritesY1 .. "0" .. spritesY1aux[i];
	end
	spritesY2aux = memory.readbyterange(0xD8,24);
	for i = 0, 23 do
		spritesY2 = spritesY2 .. "0" .. spritesY2aux[i];
	end
	
end

function resetControl(acao)
	for i = 1, 4 do
		comandos[acoes[i]] = false;
	end
	joypad.set(comandos);
	
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
end

--https://www.lua.org/pil/12.1.1.html
function serialize (o)
	if type(o) == "number" then
		io.write(o)
	elseif type(o) == "string" then
		io.write(string.format("%q", o))
	elseif type(o) == "states" then
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

--estado = 0;
objetivoX = 800; --4823
posX = 0;
posXanterior = 0;
--estadoAnterior = 0;
indiceMax = 1;

--acao = 0;
melhorScore = 0;
frames = 120; -- quantidade de frames para cada ação

function getEstadoIndex(eestado)
	for j = 1, indiceMax do
		if states[j] ~= nil and states[j][1] == eestado then
			return j;
		end
	end
	return -1;
end

function estados(estado, acao)	
	local index = getEstadoIndex(estado);
	if index == -1 then -- estado novo
		--print("states nil");
		states[indiceMax] = {estado,-1,-1,-1,-1,-1,0};
		index = indiceMax;
		savestate.save("estados/" .. index);
		indiceMax = indiceMax + 1;
	else
		savestate.load("estados/" .. index);
	end
	
	if states[index][7] == 5 then -- já realizou todas as ações
		do return end;
	end
	
	local i;
	if acao == -1 then
		for i = 2,6 do
			estados(estado,i);
		end
		do return end;
	end
	
	if states[index][acao] == 0 then
		do return end;
	end
	
	states[index][7] = states[index][7] + 1;
	
	resetControl(acao);
	
	local cont = 0;
	local j;
	for j = 1, frames do -- realiza ação
		joypad.set(comandos);
		emu.frameadvance();
		xAux = posX;
		getElementos();
		--print(marioMorre);
		if marioMorre == 9 then -- verifica se morreu a cada frame
			states[index][acao] = 0;			
			do return end;
		end
		
		if cont == 10 then
			--cont = 0;
			states[index][acao] = 0;
			do return end;
		end
		
		if posX > objetivoX then -- verifica o objetivo
			--print ("objetivo concluido!\n score: " .. score);
			--if score > melhorScore then
			--	melhorScore = score;
			--end
			--file = io.open("scores.txt","a+");
			--io.output(file);
			--io.write("\n");
			--io.write(score);		
			--io.close(file);
			--savestate.load(inicio);
			states[index][acao] = 0;
			do return end;
		end
		
		if posX == xAux then
			cont = cont+1;
		end
	end
		
	posXanterior = posX;
	scoreAnterior = score;

	local estadoAux;
	
	getElementos();
	estadoAux = posXtela .. 00 .. posYtela .. 00 .. blocos .. 00 .. spritesX1 .. 00 .. spritesY1 .. 00 .. spritesX2 .. 00 .. spritesY2 .. 00 .. inimigosID; -- .. 00 .. inimigosStatus;
	
	estados(estadoAux,-1);
	
	states[index][acao] = 0;
	
	--states[indiceAux][acao] = states[indiceAux][acao] + (learningRate* (reward + (discount*melhor) - states[indiceAux][acao]));
end


savestate.load(inicio);
getElementos();
local estado = posXtela .. 00 .. posYtela .. 00 .. blocos .. 00 .. spritesX1 .. 00 .. spritesY1 .. 00 .. spritesX2 .. 00 .. spritesY2 .. 00 .. inimigosID; -- .. 00 .. inimigosStatus;
estados(estado,-1);

print("inicializacao dos estados finalizada \n");
--print("melhor score: " .. melhorScore);


-- q-learning

ntable = {};
for i = 1, indiceMax-1 do
	ntable[i] = {};
	for j = 2, 6 do
		ntable[i][j] = 0;
	end
end

currentValue = 0;
newValue = 0;
learningRate = 0.5;
discount = 0.5;
exploration = 1;
reward = nil;
estado = nil;
acao = nil;
indexAnterior = nil;
index = nil;
score = 0;
scoreAnterior = 0;
terminal = 0;

while true do

	savestate.load(inicio);
	getElementos();
	estado = posXtela .. 00 .. posYtela .. 00 .. blocos .. 00 .. spritesX1 .. 00 .. spritesY1 .. 00 .. spritesX2 .. 00 .. spritesY2 .. 00 .. inimigosID; -- .. 00 .. inimigosStatus;
	index = getEstadoIndex(estado);

	while true do
		melhor = -99999999;
		acao = nil;
		rand = math.random();
		if rand > exploration then --exploitation
			for i = 2, 6 do -- para todas as ações
				aux = states[index][i];
				if aux > melhor then
					melhor = aux;
					acao = i;
				end
			end	
		else	-- exploration
			acao = math.random(2,6);
		end
		
		resetControl(acao);
		reward = 0;
		terminal = 0;
		local cont = 0;
		
		scoreAnterior = score;
		for j = 1, frames do -- realiza ação
			joypad.set(comandos);
			emu.frameadvance();
			local xAux = posX;
			getElementos();
			--print(marioMorre);
			if marioMorre == 9 then -- verifica se morreu a cada frame
				reward = -10000;
				terminal = 1;
				break;
			end
			
			if cont == 10 then
				reward = -10000;
				terminal = 1;
				break;
			end
			
			if posX > objetivoX then -- verifica o objetivo
				reward = scoreAnterior-score;
				terminal = 1;
				exploration = exploration-0.01;
				break;
			end
			
			if posX == xAux then
				cont = cont+1;
			end
		end
		
		if terminal == 0 then
			reward = scoreAnterior-score;
		end
		
		indexAnterior = index;
		getElementos();
		estado = posXtela .. 00 .. posYtela .. 00 .. blocos .. 00 .. spritesX1 .. 00 .. spritesY1 .. 00 .. spritesX2 .. 00 .. spritesY2 .. 00 .. inimigosID; -- .. 00 .. inimigosStatus;
		index = getEstadoIndex(estado);
			
		if index == -1 then -- novo estado
			print("novo estado");
			init = indiceMax;
			estados(estado,-1);
			for i = init, indiceMax-1 do
				ntable[i] = {};
				for j = 2, 6 do
					ntable[i][j] = 0;
				end
			end
			index = getEstadoIndex(estado);
			savestate.load("estados/" .. index);
		end
		
		if terminal == 1 then
			--print("indexAnterior " .. indexAnterior .. " acao " .. acao .. " reward " .. reward);
			states[indexAnterior][acao] = reward;
			break;
		else
			for i = 2, 6 do -- para todas as ações
				aux = states[index][i];
				if aux > melhor then
					melhor = aux;
				end
			end
			ntable[indexAnterior][acao] = ntable[indexAnterior][acao]+1;
			states[indexAnterior][acao] = states[indexAnterior][acao] + ((ntable[indexAnterior][acao])*learningRate)*(reward + discount*(melhor) - states[indexAnterior][acao]);
		end
	end
	
	getElementos();
	print("score: " .. score);
	print("exploration: " .. exploration .. "\n");
end
	-- gravar score para tabela