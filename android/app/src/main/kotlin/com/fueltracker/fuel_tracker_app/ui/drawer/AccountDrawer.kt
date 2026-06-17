package com.fueltracker.fuel_tracker_app.ui.drawer

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.ViewDay
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

/**
 * Material 3 Navigation Drawer — tham khảo cho native Android.
 * Copy vào module Compose riêng nếu cần tích hợp native.
 */
data class DrawerMenuItem(
    val id: String,
    val title: String,
    val icon: ImageVector,
)

private val drawerMenuItems = listOf(
    DrawerMenuItem("list_grid", "List Grid Card", Icons.Default.GridView),
    DrawerMenuItem("custom_scroll", "Custom Scroll View", Icons.Default.ViewDay),
    DrawerMenuItem("orders", "Đơn hàng của tôi", Icons.Default.ReceiptLong),
    DrawerMenuItem("settings", "Cài đặt", Icons.Default.Settings),
    DrawerMenuItem("logout", "Đăng xuất", Icons.AutoMirrored.Filled.Logout),
)

@Composable
fun AccountDrawerContent(
    menuItems: List<DrawerMenuItem>,
    selectedId: String?,
    onItemClick: (DrawerMenuItem) -> Unit,
    modifier: Modifier = Modifier,
    userName: String = "Nguyễn Văn A",
    userEmail: String = "nguyenvana@email.com",
) {
    Card(
        modifier = modifier
            .fillMaxHeight()
            .fillMaxWidth(0.85f),
        shape = RoundedCornerShape(topEnd = 16.dp, bottomEnd = 16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxHeight()
                .padding(16.dp),
        ) {
            AccountDrawerHeader(
                name = userName,
                email = userEmail,
            )
            HorizontalDivider(
                modifier = Modifier.padding(vertical = 8.dp),
                color = Color(0xFFE8E8E8),
            )
            LazyColumn(
                modifier = Modifier.weight(1f),
            ) {
                items(menuItems, key = { it.id }) { item ->
                    AccountDrawerMenuItem(
                        icon = item.icon,
                        title = item.title,
                        selected = item.id == selectedId,
                        onClick = { onItemClick(item) },
                    )
                }
            }
        }
    }
}

@Composable
fun AccountNavigationDrawer(
    content: @Composable () -> Unit,
) {
    val drawerState = rememberDrawerState(initialValue = androidx.compose.material3.DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    var selectedId by remember { mutableStateOf<String?>(null) }

    ModalNavigationDrawer(
        drawerState = drawerState,
        scrimColor = Color.Transparent,
        drawerContent = {
            AccountDrawerContent(
                menuItems = drawerMenuItems,
                selectedId = selectedId,
                onItemClick = { item ->
                    selectedId = item.id
                    scope.launch { drawerState.close() }
                },
            )
        },
        content = content,
    )
}

@Preview(showBackground = true, widthDp = 360, heightDp = 640)
@Composable
private fun AccountDrawerPreview() {
    MaterialTheme {
        AccountDrawerContent(
            menuItems = drawerMenuItems,
            selectedId = "list_grid",
            onItemClick = {},
        )
    }
}
