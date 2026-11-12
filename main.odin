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
    transition_timer: f32,
    timer_color: rl.Color,
    phase: Game_Phase
}

Game_Config :: struct {
    wave_duration: f32,
    enemy_count: i32,
    points_per_kill: i32,
    transition_duration: f32
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
    position := rl.Vector2 {f32(rl.GetRandomValue(100, max_x )),f32(rl.GetRandomValue(100, max_y))}
    return Enemy {position = position,alive = true, radius = 20}
}

start_next_wave :: proc(game: ^Game_State,config: Game_Config) {
    game.wave += 1
    game.enemies_killed = 0
    game.enemies_per_wave = game.wave * config.enemy_count
    game.time_remaining = config.wave_duration
    game.timer_color = rl.DARKGREEN
}

restart_game :: proc(game: ^Game_State,config: Game_Config) {
    game.score = 0
    game.wave = 1
    game.enemies_killed = 0
    game.enemies_per_wave = config.enemy_count
    game.time_remaining = config.wave_duration
    game.phase = .PLAYING
    game.timer_color = rl.DARKGREEN
}

update_cursor :: proc(phase: Game_Phase) {
    if phase == .MENU {
        rl.ShowCursor()
    } else {
        rl.HideCursor()
    }
}

main :: proc() {
    screen_width :i32 = 1280
    screen_height :i32 = 720
    should_exit := false

    rl.InitWindow(screen_width,screen_height,"kill that rabbit")
    rl.SetExitKey(.KEY_NULL)

    rabbit := rl.LoadTexture("Assets/images/rabbit.png")
    shooting_scope := rl.LoadTexture("Assets/images/shooting-scope.png")
    jungle_background := rl.LoadTexture("Assets/images/forest.png")

    game_font := rl.LoadFont("Assets/font/Pixel Game.otf")

    rabbit_scale: f32 = 4
    rabbit_width := f32(rabbit.width)
    rabbit_height := f32(rabbit.height)

    scope_width := f32(shooting_scope.width)
    scope_height := f32(shooting_scope.height)

    jungle_source := rl.Rectangle {x = 0, y = 0, width = f32(jungle_background.width), height = f32(jungle_background.height)}
    jungle_destination := rl.Rectangle {x = 0, y = 0, width = f32(screen_width),height = f32(screen_height)}

    game := Game_State{score = 0, wave = 1, enemies_killed = 0, enemies_per_wave = 5, time_remaining = 30, timer_color = rl.DARKGREEN, phase = .MENU}
    game_config := Game_Config{wave_duration = 30, enemy_count = 5, points_per_kill = 10, transition_duration = 2}
    enemy := spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)

    enter_button := rl.Rectangle{440, 340, 400, 65}
    exit_button := rl.Rectangle{440, 430, 400, 65}

    rl.HideCursor()

    for !rl.WindowShouldClose() && !should_exit{
        delta_time := rl.GetFrameTime()
        update_cursor(game.phase)
        mouse_position := rl.GetMousePosition()
        scope_position := rl.Vector2 {
            mouse_position.x - scope_width / 2,
            mouse_position.y - scope_height / 2
        }

        rabbit_rec := rl.Rectangle {
        enemy.position.x + 30,
        enemy.position.y + 30,
        rabbit_width - 50,
        rabbit_height - 50
        }

        switch game.phase{
            case .PLAYING:
                game.time_remaining -= delta_time

                if game.time_remaining <= 0 {
                    game.time_remaining = 0
                    game.phase = .GAME_OVER
                }

                if game.time_remaining <= 10 {
                    game.timer_color = rl.RED
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
                        game.transition_timer = game_config.transition_duration

                    } else if !enemy.alive {
                        enemy = spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)
                    }
                }

                if rl.IsKeyPressed(.P){
                        game.phase = .PAUSED
                }
                if rl.IsKeyPressed(.ESCAPE){
                    game.phase = .MENU
                }

            case .WAVE_COMPLETE:
                game.transition_timer -= delta_time

                if game.transition_timer <= 0 {
                    start_next_wave(&game,game_config)
                    enemy = spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)
                    game.phase = .PLAYING
                }

            case .GAME_OVER:
                if rl.IsKeyPressed(.R){
                    restart_game(&game, game_config)
                    enemy = spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)
                } else if rl.IsKeyPressed(.ESCAPE){
                    game.phase = .MENU
                }

            case .PAUSED:
                if rl.IsKeyPressed(.P){
                    game.phase = .PLAYING
                }

            case .MENU:
                if rl.IsKeyPressed(.ENTER) || (rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse_position, enter_button)){
                    restart_game(&game, game_config)
                    enemy = spawn_rabbit(screen_width,screen_height,rabbit_width,rabbit_height)
                }
                if rl.IsKeyPressed(.ESCAPE) || (rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse_position, exit_button)){
                    should_exit = true
                }
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.DrawTexturePro(jungle_background,jungle_source,jungle_destination,{0,0},0,rl.WHITE)

        switch game.phase {

            case .PLAYING:
                if enemy.alive {
                rl.DrawTextureV(rabbit,enemy.position,rl.WHITE)
                }

                rl.DrawTextureV(shooting_scope,scope_position,rl.WHITE)

                rl.DrawTextEx(game_font, rl.TextFormat("Score: %d", game.score),{20, 20}, 30,10, rl.WHITE)
                rl.DrawTextEx(game_font, rl.TextFormat("Wave: %d", game.wave),{20 ,60}, 30,10, rl.WHITE)
                rl.DrawTextEx(game_font, rl.TextFormat("Time: %.1f", game.time_remaining),{20, 100}, 30,10, game.timer_color)

            case .WAVE_COMPLETE:
                rl.DrawTextEx(game_font, rl.TextFormat("WAVE %d", game.wave + 1),{500, 300}, 60,10, rl.WHITE)
                rl.DrawTextEx(game_font, "GET READY!",{510, 380}, 25,10, rl.GOLD)

            case .GAME_OVER:
                rl.DrawTextEx(game_font, "GAME OVER",{500, 300}, 50,10, rl.RED)
                rl.DrawTextEx(game_font, rl.TextFormat("FINAL SCORE: %d", game.score),{430 ,370}, 50,10, rl.WHITE)

            case .MENU:
                rl.DrawTextEx(game_font, "Kill That Rabbit", {420, 200}, 50,10, rl.WHITE)

                rl.DrawRectangleRec(enter_button, rl.DARKGREEN)
                rl.DrawRectangleLinesEx(enter_button, 3, rl.WHITE)
                rl.DrawTextEx(game_font, "ENTER", {590, 358}, 30,10, rl.WHITE)
                
                rl.DrawRectangleRec(exit_button, rl.MAROON)
                rl.DrawRectangleLinesEx(exit_button, 3, rl.WHITE)
                rl.DrawTextEx(game_font, "EXIT", {605, 448}, 30,10, rl.WHITE)

            case .PAUSED:
                rl.DrawTextEx(game_font, "PAUSED",{550, 300}, 50 , 10, rl.WHITE)
            }

        rl.EndDrawing()
    }
    rl.UnloadFont(game_font)
    rl.UnloadTexture(jungle_background)
    rl.UnloadTexture(shooting_scope)
    rl.UnloadTexture(rabbit)
    rl.CloseWindow()
}