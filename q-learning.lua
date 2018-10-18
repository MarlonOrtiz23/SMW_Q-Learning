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
	coins = memory.read_s24_le(0xDBF);
	
	--blocosAux = memory.readbyterange(0x1BE6,256);
	--print("blocosAux[0] " .. blocosAux[0]);
	--blocos = "";
	--for i = 0, 255 do
		--print(i .. " ");
		--blocos = blocos .. "0" .. blocosAux[i];
	--end
	
	--inimigosID = "";
	--inimigosIDaux = memory.readbyterange(0x9E,12);
	--for i = 0, 11 do
		--inimigosID = inimigosID .. "0" .. inimigosIDaux[i];
	--end
	
	--inimigosStatus = "";
	--inimigosStatusaux = memory.readbyterange(0x14C8,12); -- verificar o status!!!
	--for i = 0, 11 do
		--inimigosStatus = inimigosStatus .. "0" .. inimigosStatusaux[i];
	--end
	
	marioMorre = memory.readbyte(0x71); -- 9 = morte
	
	--spritesX1 = "";
	--spritesX2 = "";
	--spritesY1 = "";
	--spritesY2 = "";
	--spritesX1aux = memory.readbyterange(0x14E8,24);
	--for i = 0, 23 do
		--spritesX1 = spritesX1 .. "0" .. spritesX1aux[i];
	--end
	--spritesX2aux = memory.readbyterange(0xE4,24);
	--for i = 0, 23 do
		--spritesX2 = spritesX2 .. "0" .. spritesX2aux[i];
	--end
	--spritesY1aux = memory.readbyterange(0x14D4,24);
	--for i = 0, 23 do
		--spritesY1 = spritesY1 .. "0" .. spritesY1aux[i];
	--end
	--spritesY2aux = memory.readbyterange(0xD8,24);
	--for i = 0, 23 do
		--spritesY2 = spritesY2 .. "0" .. spritesY2aux[i];
	--end
	
end

function resetControl(acao)
	for i = 1, 4 do
		comandos[acoes[i]] = false;
	end
	joypad.set(comandos);
	
	if acao == 0 then
		do return end
	end
	
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
objetivoX = 4823;
posX = 0;
posXanterior = 0;
--estadoAnterior = 0;
indiceMax = 0;

--acao = 0;
melhorScore = 0;
frames = 60; -- quantidade de frames para cada ação

function saveStates()
	file = io.open("states.txt","w+");
	io.output(file);
	io.write(indiceMax .. "\n");
	for i = 1,indiceMax do
		io.write(states[i][1] .. "\n");
	end
	io.close(file);
end

function copyStates()
	file = io.open("states.txt","r");
	io.input(file);
	indiceMax = tonumber(io.read());
	--print("indiceMax " .. indiceMax);
	--liness = io.read("*all");
	--i = 1;
	--for line in liness:gmatch("([^\n]*)\n?") do
	for i = 1, indiceMax do
		states[i] = {};
		states[i] = {io.read(),0,0,0,0,0,0};
		--i = i+1;
	end
	io.close(file);
end

function saveQValues()
	file = io.open("qvalues.txt","w+");
	io.output(file);
	for i = 1,indiceMax do
		for j = 2, 6 do
			io.write(states[i][j] .. "\n");
		end
	end
	io.close(file);
end

function copyQValues()
	file = io.open("qvalues.txt","r");
	io.input(file);
	--liness = io.read("*all");
	--i = 1;
	--for line in liness:gmatch("([^\n]*)\n?") do
	for i = 1, indiceMax do
		for j = 2, 6 do
			states[i][j] = tonumber(io.read());
		end
		--i = i+1;
	end
	io.close(file);
end

function saveNValues()
	file = io.open("nvalues.txt","w+");
	io.output(file);
	for i = 1,indiceMax do
		for j = 2, 6 do
			io.write(ntable[i][j] .. "\n");
		end
	end
	io.close(file);
end

function copyNValues()
	file = io.open("nvalues.txt","r");
	io.input(file);
	--liness = io.read("*all");
	--i = 1;
	--for line in liness:gmatch("([^\n]*)\n?") do
	for i = 1, indiceMax do
		--ntable[i] = {};
		for j = 2, 6 do
			ntable[i][j] = tonumber(io.read());
		end
		--i = i+1;
	end
	io.close(file);
end

function saveScore()
	file = io.open("scores.txt","a+");
	io.output(file);
	io.write(score .. "\n");
	io.close(file);
end

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
		indiceMax = indiceMax + 1;
		states[indiceMax] = {estado,-1,-1,-1,-1,-1,0};
		index = indiceMax;
		savestate.save("estados/" .. index);
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
	
	savestate.load("estados/" .. index);
	getElementos();
	posXanterior = posX;
	scoreAnterior = score;
	
	resetControl(0);
	joypad.set(comandos);
	emu.frameadvance();
	
	resetControl(acao);
	
	local cont = 1;
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
		
		if cont == frames then
			--cont = 0;
			states[index][acao] = 0;
			do return end;
		end
		
		if posX > objetivoX then -- verifica o objetivo
			states[index][acao] = 0;
			do return end;
		end
		
		if posX == xAux then
			cont = cont+1;
		end
	end

	local estadoAux;
	
	getElementos();
	--estadoAux = posXtela .. 00 .. posYtela .. 00 .. blocos .. 00 .. spritesX1 .. 00 .. spritesY1 .. 00 .. spritesX2 .. 00 .. spritesY2 .. 00 .. inimigosID; -- .. 00 .. inimigosStatus;
	estadoAux = posX .. "00" .. posY;
	
	states[index][acao] = 0;
	
	estados(estadoAux,-1);
	
	--states[indiceAux][acao] = states[indiceAux][acao] + (learningRate* (reward + (discount*melhor) - states[indiceAux][acao]));
end


--savestate.load(inicio);
--getElementos();
--estado = posXtela .. 00 .. posYtela .. 00 .. blocos .. 00 .. spritesX1 .. 00 .. spritesY1 .. 00 .. spritesX2 .. 00 .. spritesY2 .. 00 .. inimigosID; -- .. 00 .. inimigosStatus;
--estado = posX .. "00" .. posY;

--estados(estado,-1);

--print("Inicializacao dos estados finalizada \n");


--saveStates();
copyStates();

print("Quantidade de estados: " .. indiceMax);

saveQValues(); -- se quiser zerar os qvalues
copyQValues();

-- q-learning

ntable = {};
for i = 1, indiceMax do
	ntable[i] = {};
	for j = 2, 6 do
		ntable[i][j] = 0;
	end
end

saveNValues(); -- se quiser zerar os nvalues
copyNValues();

index = nil;

function qlearning()
	currentValue = 0;
	newValue = 0;
	learningRate = 1;
	discount = 1;
	exploration = 5;
	reward = 0;
	rewardAnterior = 0;
	estado = nil;
	acao = nil;
	indexAnterior = nil;
	score = 0;
	scoreAnterior = 0;
	coinsAnterior = 0;
	terminal = 0;

	--randIndex = math.random(1,indiceMax);
	--savestate.load(inicio);
	savestate.load("estados/" .. index);
	getElementos();
	--estado = posXtela .. 00 .. posYtela .. 00 .. blocos .. 00 .. spritesX1 .. 00 .. spritesY1 .. 00 .. spritesX2 .. 00 .. spritesY2 .. 00 .. inimigosID; -- .. 00 .. inimigosStatus;
	estado = posX .. "00" .. posY;
	--index = getEstadoIndex(estado);
	--index = randIndex;
	--continue = 0;
	
	---savestate.load("estados/" .. index);
	---getElementos();
	
	while true do
		if index == -1 then
			init = indiceMax;
			estados(estado,-1);
			index = getEstadoIndex(estado);
			for i = init, indiceMax do
				ntable[i] = {};
				for j = 2, 6 do
					ntable[i][j] = 0;
				end
			end
			saveStates();
			saveQValues();
			saveNValues();
			savestate.load("estados/" .. index);
			getElementos();
		end
		
		melhor = -9999999999;
		pior = 9999999999;
		acao = nil;
		rand = math.random(0,10);
		if rand > exploration then --exploitation
			lista = nil;
			for i = 2, 6 do -- para todas as ações
				aux = states[index][i];
				if i == 2 then
					melhor = aux;
					acao = i;
				elseif aux > melhor then
					melhor = aux;
					acao = i;
					lista = nil;
				elseif aux == melhor then
					if lista == nil then
						lista = {};
						lista[1] = i;
						lista[2] = acao;
						indexLista = 3;
					else
						lista[indexLista] = i;
						indexLista = indexLista+1;
					end
				end
			end
			if lista ~= nil then
				acao = lista[math.random(1,indexLista-1)];
			end
		else	-- exploration
			lista = nil;
			for i = 2, 6 do -- para todas as ações
				aux = ntable[index][i];
				if i == 2 then
					pior = aux;
					acao = i;
				elseif aux < pior then
					pior = aux;
					acao = i;
					lista = nil;
				elseif aux == pior then
					if lista == nil then
						lista = {};
						lista[1] = i;
						lista[2] = acao;
						indexLista = 3;
					else
						lista[indexLista] = i;
						indexLista = indexLista+1;
					end
				end
			end
			if lista ~= nil then
				acao = lista[math.random(1,indexLista-1)];
			end
		end
		
		resetControl(0);
		joypad.set(comandos);
		emu.frameadvance();
		
		resetControl(acao);
		terminal = 0;
		local cont = 1;
		
		rewardAnterior = reward;
		scoreAnterior = score;
		coinsAnterior = coins;
		indexAnterior = index;
		posXanterior = posX;
		--print("index " .. index .. " acao " .. acao);
		
		if ntable[index][acao] < 20 then
			ntable[index][acao] = ntable[index][acao]+1;
		end
		
		for j = 1, frames do -- realiza ação
			joypad.set(comandos);
			emu.frameadvance();
			local xAux = posX;
			getElementos();
			--print(marioMorre);
			if marioMorre == 9 then -- verifica se morreu a cada frame
				reward = -100;
				terminal = 1;
				break;
			end
			
			if cont == frames then
				reward = -100;
				terminal = 1;
				break;
			end
			
			if posX > objetivoX then -- verifica o objetivo
				reward = (coins - coinsAnterior)+((score - scoreAnterior)/10)+100;
				terminal = 1;
				--exploration = exploration-0.1;
				saveScore();
				break;
			end
			
			if posX == xAux then
				cont = cont+1;
			end
		end
		
		if terminal == 0 then
			reward = (coins - coinsAnterior)+(score - scoreAnterior)/10;
		end
		
		getElementos();
		--estado = posXtela .. 00 .. posYtela .. 00 .. blocos .. 00 .. spritesX1 .. 00 .. spritesY1 .. 00 .. spritesX2 .. 00 .. spritesY2 .. 00 .. inimigosID; -- .. 00 .. inimigosStatus;
		estado = posX .. "00" .. posY;
		index = getEstadoIndex(estado);
		
		if terminal == 1 then -- objetivo alcancado
			--print("indexAnterior " .. indexAnterior .. " acao " .. acao .. " reward " .. reward);
			states[indexAnterior][acao] = reward;
			--if exploration > 0 then
			--	exploration = exploration - 0.01;
			--end
			break;
		end
		
		--ver = 0;
		--if terminal == 1 then -- morreu
		--	states[indexAnterior][acao] = reward;
		--	savestate.load("estados/" .. indexAnterior);
		--	if(continue == 20) then break end;
		--	continue = continue + 1;
		--	ver = 1;
		--end
		
		--if(ver == 0) then
		--continue = 0;
		melhor = -9999999999;
		if index == -1 then
			melhor = 0;
		else
			for i = 2, 6 do -- para todas as ações
				aux = states[index][i];
				if aux > melhor then
					melhor = aux;
				end
			end
		end
		
		states[indexAnterior][acao] = states[indexAnterior][acao] + (learningRate*ntable[indexAnterior][acao])*(rewardAnterior + (discount*melhor) - states[indexAnterior][acao]);
		--print("estado: " .. indexAnterior .. " acao: " .. acao .. " qvalue: " .. states[indexAnterior][acao] .. " frequencia: " .. ntable[indexAnterior][acao]);
		--end
	end
	
	--print("score: " .. score);
	--print("exploration: " .. exploration .. "\n");
	saveQValues();
	saveNValues();
end

function exploration()
	print("inicio: " .. os.date("%c"));
	exploration = 100; -- exploration only
	for i = 1, indiceMax do
		index = i;
		print("estado " .. i);
		qlearning();
	end
	print("termino: " .. os.date("%c"));
end

function exploration2()
	exploration = 100;
	for i = 1, 200 do
		index = 1;
		qlearning();
		exploration = exploration-1;
	end
end

function exploitation()
	exploration = -100; -- exploitation only
	for i = 1, 10 do
		index = 1;
		qlearning();
	end
end


--exploration();
--exploration2();
exploitation();
