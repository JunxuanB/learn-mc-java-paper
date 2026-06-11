package dev.learnpaper.hello;

import java.util.List;

import org.bukkit.command.PluginCommand;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.plugin.java.JavaPlugin;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;

public final class LearnPaperHelloPlugin extends JavaPlugin implements Listener {
    @Override
    public void onEnable() {
        getServer().getPluginManager().registerEvents(this, this);

        PluginCommand helloCommand = getCommand("hello");
        if (helloCommand != null) {
            helloCommand.setExecutor((sender, command, label, args) -> {
                if (sender instanceof Player player) {
                    player.sendMessage(Component.text("Hello, " + player.getName() + "!", NamedTextColor.GREEN)
                            .append(Component.text(" You are in " + player.getWorld().getName() + ".", NamedTextColor.GRAY)));
                } else {
                    sender.sendMessage(Component.text("Hello from LearnPaperHello!", NamedTextColor.GREEN));
                }
                return true;
            });

            helloCommand.setTabCompleter((sender, command, alias, args) -> {
                if (args.length == 1) {
                    return List.of("paper", "world", "me");
                }
                return List.of();
            });
        }

        getLogger().info("LearnPaperHello enabled. Try /hello in game or in the console.");
    }

    @EventHandler
    public void onPlayerJoin(PlayerJoinEvent event) {
        event.getPlayer().sendMessage(Component.text("Welcome! Type /hello to test the plugin.", NamedTextColor.AQUA));
    }
}
