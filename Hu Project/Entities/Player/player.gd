extends CharacterBody2D

# Velocidade padrão de caminhada do jogador
@export var walk_speed : int = 250
# Velocidade de corrida do jogador
@export var run_speed : int = 500
# Taxa de desaceleração horizontal; define a suavidade ao parar de andar
@export_range(0, 1) var deceleration : float = 0.1
# Taxa de aceleração horizontal; define a suavidade ao começar a andar
@export_range(0, 1) var acceleration : float = 0.1

# Força do pulo do jogador; valor negativo para indicar movimento para cima
@export var jump_force : int = -500
# Redução da velocidade vertical ao soltar o botão de pulo antes do ápice
@export_range(0, 1) var decelerate_on_jump_release : float = 0.5

# Define o quão rápido o jogador se move durante o dash
@export var dash_speed : int = 1000
# Distância máxima que o dash pode alcançar
@export var dash_max_distance : int = 300
# Curva de aceleração/desaceleração do dash, permitindo ajustar a suavidade do movimento
# (Essa curva é configurada diretamente no editor do Godot)
@export var dash_curve : Curve
# Tempo de recarga (cooldown) entre dashes, em segundos
@export var dash_cooldown : int = 1
# Indica se o jogador está atualmente executando um dash
var is_dashing : bool = false
# Posição inicial do jogador no início do dash
var dash_start_position : float = 0
# Direção do dash; -1 para esquerda, 1 para direita
var dash_dir : float = 0
# Temporizador usado para controlar a duração do dash e a recarga
var dash_timer : float = 0

# Força da gravidade aplicada ao jogador, obtida diretamente configurações do projeto
@export var gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")

# Captura a entrada do jogador para movimentação horizontal e ajusta velocidade
func get_input(delta : float) -> void:
	# Captura a direção horizontal (-1 para esquerda, 1 para direita, 0 parado)
	var dir : float = Input.get_axis("left", "right")
	# Define a velocidade com base na ação de correr ou caminhar
	var speed : int
	
	# Verifica se a tecla "run" está pressionada e se o jogador está no chão
	if Input.is_action_pressed("run") and is_on_floor():
		speed = run_speed # Usa a velocidade de corrida
	else:
		speed = walk_speed # Usa a velocidade padrão de caminhada
	
	# Aplica a aceleração ou desaceleração à velocidade horizontal
	if dir: # Se há entrada de direção
		velocity.x = move_toward(velocity.x, dir * speed, speed * acceleration)
	else: # Caso contrário, desacelera gradualmente
		velocity.x = move_toward(velocity.x, 0, speed * deceleration)
	
	# Verifica se a tecla "dash" está pressionada, se há direção (dir != 0),
	# se o jogador não está atualmente dendo um dash e se o cooldown terminou
	if Input.is_action_just_pressed("dash") and dir and not is_dashing and dash_timer <=0:
		is_dashing = true # Inicia o dash
		dash_start_position = position.x # Armazena a posição horizontal inicial do dash
		dash_dir = dir # Define a direção do dash com base na entrada do jogador (-1 ou 1)
		dash_timer = dash_cooldown # Inicia o cooldown do dash
	
	# Verifica se o jogador está atualmente dando um dash
	if is_dashing:
		# Calcula a distância percorrida desde o início do dash
		var current_distance : float = abs(position.x - dash_start_position)
		
		# Interrompe o dash se atingir a distância máxima ou colidir com uma parede
		if current_distance >= dash_max_distance or is_on_wall():
			is_dashing = false
		else:
			# Continua o dash, ajustando a velocidade horizontal com base na curva do dash
			# 'dash_curve.sample()' retorna um valor entre 0 e 1, ajustando a aceleração/desaceleração
			velocity.x = dash_dir * dash_speed * dash_curve.sample(current_distance / dash_max_distance)
			velocity.y = 0 # Zera a velocidade vertical para evitar que o jogador caia durante o dash
	
	# Reduz o temporizador de cooldown do dash, se ele ainda estiver acima de 0
	if dash_timer > 0:
		dash_timer -= delta

# Controla o comportamento de pulo e queda do jogador
func jump(delta: float) -> void:
	# Verifica se a tecla "jump" está pressionada e se o jogador está no chão
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force # Aplica a força do pulo
	else:
		velocity.y += gravity * delta # Aplica a gravidade enquanto o jogador está no ar
	
	# Verifica se a tecla "jump" foi solta antes do ápice do pulo
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release # Reduz a velocidade vertical; efeito de pulo mais "curto"

# Automaticamente chamada quando o nó é instanciado
func _ready() -> void:
	pass # Placeholder; substitua pelo corpo da função

# Processamento de física chamado a cada frame
func _physics_process(delta : float) -> void:
	# Chama a função get_input()
	get_input(delta)
	# Chama a função jump(delta)
	jump(delta)
	# Move o personagem com base na direção e velocidade calculadas (velocity)
	move_and_slide()
