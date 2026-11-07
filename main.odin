package game

import rl "vendor:raylib"

Enemy :: struct {
    position: rl.Vector2,
    alive: bool,
    radius: f32
}

Game_State :: struct {
    score: i32,
    wave: i32,
    enemies_killed: i32,
    enemies_per_wave: i32,
    time_remaining: f32,
    phase: Game_Phase
}

Game_Config :: struct {
    wave_duration: f32,
    enemy_count: i32,
    points_per_kill: i32
}

Game_Phase :: enum {
    MENU,
    PLAYING,
    PAUSED,
    WAVE_COMPLETE,
    GAME_OVER
}

spawn_rabbit:: proc(screen_width, screen_height: i32, enemy_width, enemy_height: f32)-> Enemy {
    max_x := screen_width - i32(enemy_width)
    max_y := screen_height - i32(enemy_height)
    position := rl.Vector2 {f32(rl.GetRandomValue(64, max_x )),f32(rl.GetRandomValue(64, max_y))}
    return Enemy {position = position,alive = true, radius = 20}
}

start_next_wave :: proc(game: ^Game_State,config: Game_Config) {
    game.wave += 1
    game.enemies_killed = 0
    game.enemies_per_wave += 2
    game.time_remaining = config.wave_duration
}

main :: proc() {
    screen_width :i32 = 1280
    screen_height :i32 = 720
    game_pauesd:bool

    rl.InitWindow(screen_width,screen_height,"hunting game")

    rabbit := rl.LoadTexture("Assets/rabbit.png")
    shooting_scope := rl.LoadTexture("Assets/shooting-scope.png")
    jungle_background := rl.LoadTexture("Assets/forest.png")

    rabbit_scale: f32 = 4
    rabbit_width := f32(rabbit.width) * rabbit_scale
    rabbit_height := f32(rabbit.height) * rabbit_scale
    rabbit_visible_size: f32 = 12
    rabbit_padding := (f32(rabbit.width) - rabbit_visible_size) / 2

    scope_width := f32(shooting_scope.width)
    scope_height := f32(shooting_scope.height)

    jungle_source := rl.Rectangle {x = 0, y = 0, width = f32(jungle_background.width), height = f32(jungle_background.height)}
    jungle_destination := rl.Rectangle {x = 0, y = 0, width = f32(screen_width),height = f32(screen_height)}

    game := Game_State{score = 0, wave = 1, enemies_killed = 0, enemies_per_wave = 5, time_remaining = 30, phase = .PLAYING}
    game_config := Game_Config{wave_duration = 30, enemy_count = 5,points_per_kill = 10}
    enemy := spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)

    timer_color := rl.GREEN

    rl.HideCursor()

    for !rl.WindowShouldClose(){
        delta_time := rl.GetFrameTime()
        mouse_position := rl.GetMousePosition()
        scope_position := rl.Vector2 {
            mouse_position.x - scope_width / 2,
            mouse_position.y - scope_height / 2
        }

        rabbit_rec := rl.Rectangle {
        enemy.position.x + rabbit_padding * rabbit_scale,
        enemy.position.y + rabbit_padding * rabbit_scale,
        rabbit_visible_size * rabbit_scale,
        rabbit_visible_size * rabbit_scale
        }

        switch game.phase{

            case .PLAYING:
            game.time_remaining -= delta_time

            if game.time_remaining <= 0 {
                game.time_remaining = 0
                game.phase = .GAME_OVER
            }

            if game.time_remaining <= 10 {
                timer_color = rl.RED
            }

            if game.phase == .PLAYING &&
                rl.IsMouseButtonPressed(.LEFT) &&
                enemy.alive &&
                rl.CheckCollisionPointRec(mouse_position, rabbit_rec){
                game.score += game_config.points_per_kill
                game.enemies_killed += 1

                enemy.alive = false
            }

            if game.phase == .PLAYING{
                if game.enemies_killed >= game.enemies_per_wave {
                    game.phase = .WAVE_COMPLETE

                    enemy = spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)
                } else if !enemy.alive {
                    enemy = spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)
                }
            }

            if rl.IsKeyPressed(.P){
                    game.phase = .PAUSED
            }
            
            case .WAVE_COMPLETE:
                start_next_wave(&game,game_config)
                enemy = spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)
                game.phase = .PLAYING

            case .GAME_OVER:

            case .PAUSED:
                if rl.IsKeyPressed(.P){
                    game.phase = .PLAYING
                }

            case .MENU:
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.DrawTexturePro(jungle_background,jungle_source,jungle_destination,{0,0},0,rl.WHITE)

        switch game.phase {
        
        case .PLAYING:
            if enemy.alive {
            rl.DrawTextureEx(rabbit,enemy.position,0,rabbit_scale,rl.WHITE)
            }

            rl.DrawTextureV(shooting_scope,scope_position,rl.WHITE)

            rl.DrawText(rl.TextFormat("Score: %d", game.score),20, 20, 30, rl.WHITE)
            rl.DrawText(rl.TextFormat("Wave: %d", game.wave),20, 60, 30, rl.WHITE)
            rl.DrawText(rl.TextFormat("Time: %.1f", game.time_remaining),20, 100, 30, timer_color)
        
        case .WAVE_COMPLETE:

        case .GAME_OVER:
            rl.DrawText("GAME OVER",500, 300, 50, rl.RED)
            rl.DrawText(rl.TextFormat("FINAL SCORE: %d", game.score),500, 370, 30, rl.WHITE)
            
        case .MENU:
                
        case .PAUSED:
            rl.DrawText("PAUSED",550, 300, 50, rl.WHITE)
        }
                
        rl.EndDrawing()

    }
    rl.UnloadTexture(jungle_background)
    rl.UnloadTexture(shooting_scope)
    rl.UnloadTexture(rabbit)
    rl.CloseWindow()
}